import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        const { user_id, title, body, secret } = await req.json()

        // 1. Verify Secret
        const adminPassword = Deno.env.get('ADMIN_PASSWORD')
        if (secret !== adminPassword) {
            return new Response(JSON.stringify({ error: 'Unauthorized' }), {
                status: 401,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            })
        }

        if (!user_id || !title || !body) {
            return new Response(JSON.stringify({ error: 'User ID, title and body are required' }), {
                status: 400,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            })
        }

        // 2. Validate User ID
        const { data: userData, error: userError } = await supabase
            .from('profiles')
            .select('id')
            .eq('id', user_id)
            .maybeSingle()

        if (userError || !userData) {
            return new Response(JSON.stringify({ error: 'User not found' }), {
                status: 404,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            })
        }

        // 3. Insert Notification into scheduled_alerts
        // Dispatch immediately
        const triggerAt = new Date().toISOString()

        // Use a unique alert_key so multiple DMs can be sent to the same user without conflicts over time
        const alert_key = `direct_message_${Date.now()}`

        const { error: insertError } = await supabase
            .from('scheduled_alerts')
            .insert({
                user_id: user_id,
                title: title,
                body: body,
                type: 'direct_message',
                alert_key: alert_key,
                trigger_at: triggerAt,
                is_dispatched: false
            })

        if (insertError) throw insertError

        return new Response(JSON.stringify({
            success: true,
            message: `Message queued for user ${user_id}`
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })

    } catch (err: any) {
        return new Response(JSON.stringify({ error: err.message }), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
    }
})
