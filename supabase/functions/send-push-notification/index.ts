import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { create, getNumericDate } from 'https://deno.land/x/djwt@v2.8/mod.ts'

console.log('FCM Push Notification function started')

serve(async (req) => {
    try {
        const payload = await req.json()
        const notification = payload.record

        if (!notification || !notification.user_id) {
            return new Response(JSON.stringify({ error: 'Invalid payload' }), { status: 400 })
        }

        const supabaseUrl = Deno.env.get('SUPABASE_URL')
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
        const supabase = createClient(supabaseUrl!, supabaseKey!)

        // 1. Fetch ALL FCM tokens for the user
        const { data: fcmTokens, error: fcmError } = await supabase
            .from('fcm_tokens')
            .select('token, platform')
            .eq('user_id', notification.user_id)

        if (fcmError || !fcmTokens || fcmTokens.length === 0) {
            console.log(`No FCM tokens found for user ${notification.user_id}`)
            await supabase.from('notifications').update({ 
                is_dispatched: false
            }).eq('id', notification.id)
            return new Response(JSON.stringify({ message: 'No FCM tokens, skipping.' }), { status: 200 })
        }

        const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
        if (!serviceAccountStr) {
            console.error("Missing FIREBASE_SERVICE_ACCOUNT secret.")
            return new Response(JSON.stringify({ error: 'Feature disabled' }), { status: 500 })
        }

        const serviceAccount = JSON.parse(serviceAccountStr)
        const accessToken = await getFirebaseAccessToken(serviceAccount)
        const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`

        let successCount = 0
        let failureCount = 0
        const results = []

        // 2. Loop through all tokens and send
        for (const { token } of fcmTokens) {
            const fcmPayload = {
                message: {
                    token: token,
                    notification: {
                        title: notification.title || 'New Notification',
                        body: notification.body || '',
                    },
                    data: {
                        notification_id: notification.id?.toString() || '',
                        type: notification.type || 'default',
                    },
                    android: {
                        priority: 'high',
                        notification: {
                            icon: '@mipmap/ic_launcher',
                            sound: 'default'
                        }
                    },
                    apns: {
                        payload: {
                            aps: {
                                sound: 'default',
                                badge: 1
                            }
                        }
                    }
                }
            }

            try {
                const response = await fetch(fcmUrl, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        Authorization: `Bearer ${accessToken}`,
                    },
                    body: JSON.stringify(fcmPayload),
                })

                const result = await response.json()

                if (response.ok) {
                    successCount++
                    results.push({ token: token.substring(0, 10), success: true, messageId: result.name })
                } else {
                    failureCount++
                    results.push({ token: token.substring(0, 10), success: false, error: result.error })
                    
                    // 3. Auto-cleanup stale tokens
                    if (result.error?.status === 'UNREGISTERED' || 
                        result.error?.status === 'NOT_FOUND' || 
                        result.error?.status === 'INVALID_ARGUMENT') {
                        console.log(`Removing stale token: ${token.substring(0, 15)}... Error: ${result.error?.status}`)
                        await supabase.from('fcm_tokens').delete().eq('token', token)
                    }
                }
            } catch (err) {
                console.error(`Error sending to token ${token.substring(0, 10)}:`, err)
                failureCount++
            }
        }

        // 4. Update notification record with results
        await supabase.from('notifications').update({
            is_dispatched: successCount > 0
        }).eq('id', notification.id)

        console.log(`Push execution finished. Success: ${successCount}, Failures: ${failureCount}`)
        
        return new Response(JSON.stringify({ 
            success: successCount > 0, 
            sent_count: successCount,
            failed_count: failureCount
        }), {
            headers: { 'Content-Type': 'application/json' },
        })

    } catch (err) {
        console.error('Global Function error:', err)
        return new Response(JSON.stringify({ error: 'Internal Server Error' }), { status: 500 })
    }
})

async function getFirebaseAccessToken(serviceAccount: any): Promise<string> {
    const iat = getNumericDate(0)
    const exp = getNumericDate(3600)

    const payload = {
        iss: serviceAccount.client_email,
        sub: serviceAccount.client_email,
        aud: 'https://oauth2.googleapis.com/token',
        iat,
        exp,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
    }

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
