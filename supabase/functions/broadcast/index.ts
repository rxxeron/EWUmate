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

        const { title, body, link, scheduledAt, secret } = await req.json()

        // 1. Verify Secret
        const adminPassword = Deno.env.get('ADMIN_PASSWORD')
        if (secret !== adminPassword) {
            return new Response(JSON.stringify({ error: 'Unauthorized' }), {
                status: 401,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            })
        }

        if (!title || !body) {
            return new Response(JSON.stringify({ error: 'Title and body are required' }), {
                status: 400,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            })
        }

        // 2. Fetch all user IDs
        // We use a small limit here for testing if needed, but for production it should be all
        const { data: users, error: userError } = await supabase
            .from('profiles')
            .select('id')

        if (userError) throw userError

        if (!users || users.length === 0) {
            return new Response(JSON.stringify({ success: true, message: 'No users to broadcast to.' }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            })
        }

        // 3. Prepare Batch Insert into scheduled_alerts
        const triggerAt = scheduledAt ? new Date(scheduledAt).toISOString() : new Date().toISOString()
        const metadata = link ? { link } : {}

        const alerts = users.map(user => ({
            user_id: user.id,
            title: title,
            body: body,
            trigger_at: triggerAt,
            type: 'broadcast',
            metadata: metadata,
            is_dispatched: false
        }))

        // Insert in batches of 100 to avoid limits
        for (let i = 0; i < alerts.length; i += 100) {
            const batch = alerts.slice(i, i + 100)
            const { error: insertError } = await supabase
                .from('scheduled_alerts')
                .insert(batch)

            if (insertError) throw insertError
        }

        return new Response(JSON.stringify({
            success: true,
            message: `Broadcast scheduled for ${users.length} users at ${triggerAt}`
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
