import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

// Use Google's official library to handle OAuth2 to get an FCM access token
// (Using a polyfill since Deno doesn't natively have googleapis npm package easily available in edge functions without import maps)
// A common approach is to use standard JWT signing using the Service Account JSON
import { create, getNumericDate } from 'https://deno.land/x/djwt@v2.8/mod.ts'

console.log('FCM Push Notification function started')

serve(async (req) => {
    try {
        // 1. Verify this request came from Supabase (Webhook Secret)
        // Optional but recommended: check req.headers.get("webhook-secret")

        // 2. Parse the webhook payload
        const payload = await req.json()
        const notification = payload.record // The new row in the `notifications` table

        if (!notification || !notification.user_id) {
            return new Response(JSON.stringify({ error: 'Invalid payload' }), { status: 400 })
        }

        // 3. Initialize Supabase Client with Service Role (Bypasses RLS to read FCM tokens)
        const supabaseUrl = Deno.env.get('SUPABASE_URL')
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
        const supabase = createClient(supabaseUrl!, supabaseKey!)

        // 4. Fetch the user's FCM token
        const { data: fcmData, error: fcmError } = await supabase
            .from('fcm_tokens')
            .select('token')
            .eq('user_id', notification.user_id)
            .single()

        if (fcmError || !fcmData || !fcmData.token) {
            console.log(`No FCM token found for user ${notification.user_id}`)
            return new Response(JSON.stringify({ message: 'No FCM token, skipping.' }), { status: 200 })
        }

        const deviceToken = fcmData.token

        // 5. Build the Firebase HTTP v1 API Request
        // You MUST set FIREBASE_SERVICE_ACCOUNT in your Supabase Dashboard Secrets
        // It should be the full JSON string of your Firebase Service Account key
        const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
        if (!serviceAccountStr) {
            console.error("Missing FIREBASE_SERVICE_ACCOUNT secret.")
            return new Response(JSON.stringify({ error: 'Feature disabled' }), { status: 500 })
        }

        const serviceAccount = JSON.parse(serviceAccountStr)
        const accessToken = await getFirebaseAccessToken(serviceAccount)

        const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`

        // 6. Send the Push Notification
        const fcmPayload = {
            message: {
                token: deviceToken,
                notification: {
                    title: notification.title || 'New Notification',
                    body: notification.body || '',
                },
                data: {
                    notification_id: notification.id,
                    type: notification.type || 'default',
                },
                android: {
                    priority: 'high',
                    notification: {
                        icon: '@mipmap/ic_launcher',
                        sound: 'default'
                    }
                }
            }
        }

        const response = await fetch(fcmUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${accessToken}`,
            },
            body: JSON.stringify(fcmPayload),
        })

        const result = await response.json()

        if (!response.ok) {
            console.error('FCM API Error:', result)
            return new Response(JSON.stringify({ error: 'Failed to send push' }), { status: 500 })
        }

        console.log('Push sent successfully:', result)
        return new Response(JSON.stringify({ success: true, messageId: result.name }), {
            headers: { 'Content-Type': 'application/json' },
        })
    } catch (err) {
        console.error('Function error:', err)
        return new Response(JSON.stringify({ error: 'Internal Server Error' }), { status: 500 })
    }
})

// Helper to generate a Google Cloud OAuth2 Access Token using JWT
async function getFirebaseAccessToken(serviceAccount: any): Promise<string> {
    const iat = getNumericDate(0)
    const exp = getNumericDate(3600) // 1 hour

    const payload = {
        iss: serviceAccount.client_email,
        sub: serviceAccount.client_email,
        aud: 'https://oauth2.googleapis.com/token',
        iat,
        exp,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
    }

    // Convert the private key from string to a CryptoKey
    const pemHeader = "-----BEGIN PRIVATE KEY-----"
    const pemFooter = "-----END PRIVATE KEY-----"
    const pemContents = serviceAccount.private_key
        .replace(pemHeader, "")
        .replace(pemFooter, "")
        .replace(/\s+/g, "")

    const binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0))

    const cryptoKey = await crypto.subtle.importKey(
        "pkcs8",
        binaryDer,
        { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
        false,
        ["sign"]
    )

    const jwt = await create({ alg: "RS256", typ: "JWT" }, payload, cryptoKey)

    const body = new URLSearchParams()
    body.append('grant_type', 'urn:ietf:params:oauth:grant-type:jwt-bearer')
    body.append('assertion', jwt)

    const res = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: body.toString(),
    })

    const data = await res.json()
    return data.access_token
}
