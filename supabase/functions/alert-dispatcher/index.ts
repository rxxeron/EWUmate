import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const FCM_SERVICE_ACCOUNT = Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "";

serve(async (req: Request) => {
    try {
        if (req.method !== 'POST') {
            return new Response('Method not allowed', { status: 405 });
        }

        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
        const utcTimestamp = new Date().toISOString();
        console.log(`Alert Dispatcher started at ${utcTimestamp}`);

        try {
            // 1. Fetch pending alerts
            const { data: pending, error: fetchError } = await supabase
                .from("scheduled_alerts")
                .select("*")
                .eq("is_dispatched", false)
                .lte("trigger_at", utcTimestamp);

            if (fetchError) throw fetchError;
            if (!pending || pending.length === 0) {
                return new Response(JSON.stringify({ message: "No pending alerts." }), { status: 200 });
            }

            console.log(`Processing ${pending.length} alerts.`);

            // 2. Prepare FCM Auth if secret exists
            let fcmAccessToken = "";
            let fcmProjectId = "";

            if (FCM_SERVICE_ACCOUNT) {
                try {
                    const serviceAccount = JSON.parse(FCM_SERVICE_ACCOUNT);
                    fcmProjectId = serviceAccount.project_id;

                    console.log("Requesting FCM access token securely natively...");
                    fcmAccessToken = await getFirebaseAccessToken(serviceAccount);
                    console.log("FCM Access Token acquired!");
                } catch (authErr: any) {
                    console.error("FCM Native JWT Parse/Auth Error:", authErr.message);
                }
            } else {
                console.log("FIREBASE_SERVICE_ACCOUNT secret missing.");
            }

            let dispatchedCount = 0;
            let fcmErrors: string[] = [];

            for (const alert of pending) {
                try {
                    // A. Insert into in-app notifications
                    await supabase.from("notifications").insert({
                        user_id: alert.user_id,
                        title: alert.title,
                        body: alert.body,
                        type: alert.type || 'system',
                        data: alert.metadata || {}
                    });

                    // B. Send Push Notification via FCM
                    if (fcmAccessToken && fcmProjectId) {
                        // Get device tokens for THIS user
                        const { data: userTokens } = await supabase
                            .from("fcm_tokens")
                            .select("token")
                            .eq("user_id", alert.user_id);

                        if (userTokens && userTokens.length > 0) {
                            for (const { token } of userTokens) {
                                try {
                                    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${fcmProjectId}/messages:send`;
                                    const fcmPayload = {
                                        message: {
                                            token: token,
                                            notification: {
                                                title: alert.title,
                                                body: alert.body,
                                            },
                                            android: {
                                                priority: "high",
                                                notification: {
                                                    channelId: "ewumate_task_reminders", // Match your flutter channel
                                                    icon: "@mipmap/ic_launcher", // Prevents fatal UI crash on Android skins
                                                    sound: "default"
                                                }
                                            },
                                            data: {
                                                alert_id: alert.id.toString(),
                                                type: alert.type || 'system'
                                            }
                                        }
                                    };

                                    const fcmRes = await fetch(fcmUrl, {
                                        method: "POST",
                                        headers: {
                                            "Content-Type": "application/json",
                                            Authorization: `Bearer ${fcmAccessToken}`,
                                        },
                                        body: JSON.stringify(fcmPayload),
                                    });

                                    if (!fcmRes.ok) {
                                        const errText = await fcmRes.text();
                                        fcmErrors.push(`Token ${token.substring(0, 5)}...: ${errText}`);
                                        console.error(`FCM send error for token ${token.substring(0, 10)}...:`, errText);
                                    }
                                } catch (e: any) {
                                    fcmErrors.push(`FCM Request Catch: ${e.message}`);
                                    console.error("FCM Request failed:", e);
                                }
                            }
                        } else {
                            fcmErrors.push(`No tokens found in DB for user ${alert.user_id}`);
                        }
                    } else {
                        fcmErrors.push("Missing fcmAccessToken or fcmProjectId");
                    }

                    // C. Mark as dispatched
                    await supabase
                        .from("scheduled_alerts")
                        .update({ is_dispatched: true, dispatched_at: new Date().toISOString() })
                        .eq("id", alert.id);

                    dispatchedCount++;
                } catch (err: any) {
                    fcmErrors.push(`Failed alert ${alert.id}: ${err.message}`);
                    console.error(`Failed alert ${alert.id}:`, err);
                }
            }

            return new Response(JSON.stringify({ message: `Dispatched ${dispatchedCount} alerts.`, fcmErrors }), { status: 200, headers: { "Content-Type": "application/json" } });

        } catch (err: any) {
            console.error("Fatal Dispatcher Error:", err);
            return new Response(JSON.stringify({
                error: "Internal Error",
                details: err.message
            }), { status: 500, headers: { "Content-Type": "application/json" } });
        }
    } catch (globalErr: any) {
        return new Response(JSON.stringify({ error: "Global Setup Error", details: globalErr.message }), { status: 500 });
    }
});

// Helper to generate a Google Cloud OAuth2 Access Token using Deno Native Crypto
async function getFirebaseAccessToken(serviceAccount: any): Promise<string> {
    const iat = getNumericDate(0);
    const exp = getNumericDate(3600); // 1 hour

    const payload = {
        iss: serviceAccount.client_email,
        sub: serviceAccount.client_email,
        aud: 'https://oauth2.googleapis.com/token',
        iat,
        exp,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
    };

    const pemHeader = "-----BEGIN PRIVATE KEY-----";
    const pemFooter = "-----END PRIVATE KEY-----";
    const pemContents = serviceAccount.private_key
        .replace(pemHeader, "")
        .replace(pemFooter, "")
        .replace(/\\n/g, "")
        .replace(/\s+/g, "");

    const binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0));

    const cryptoKey = await crypto.subtle.importKey(
        "pkcs8",
        binaryDer,
        { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
        false,
        ["sign"]
    );

    const jwt = await create({ alg: "RS256", typ: "JWT" }, payload, cryptoKey);

    const body = new URLSearchParams();
    body.append('grant_type', 'urn:ietf:params:oauth:grant-type:jwt-bearer');
    body.append('assertion', jwt);

    const res = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: body.toString(),
    });

    if (!res.ok) {
        const errorText = await res.text();
        throw new Error(`Google Auth Token request failed: ${res.status} ${errorText}`);
    }

    const data = await res.json();
    return data.access_token;
}
