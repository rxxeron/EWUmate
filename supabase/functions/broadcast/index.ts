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
        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
        const supabase = createClient(supabaseUrl, supabaseKey);

        let { title, body, link, scheduledAt, targetUserId, targetDepartment, targetStatus } = await req.json();

        if (!title || !body) {
            return new Response(JSON.stringify({ error: 'Title and body are required' }), {
                status: 400,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        // 1. Build Query
        let query = supabase.from('profiles').select('id');
        
        if (targetUserId) {
            targetUserId = targetUserId.trim();
            query = query.eq('id', targetUserId);
        }
        if (targetDepartment) {
            query = query.eq('department_name', targetDepartment);
        }
        if (targetStatus) {
            query = query.eq('onboarding_status', targetStatus);
        }

        const { data: users, error: userError } = await query;

        if (userError) throw userError;

        if (!users || users.length === 0) {
            return new Response(JSON.stringify({ success: true, message: 'No matching users found to broadcast to.' }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        // 2. Prepare Batch Insert into 'notifications' (unified table)
        const triggerAt = scheduledAt ? new Date(scheduledAt).toISOString() : new Date().toISOString();
        const payloadData = link ? { url: link } : {};

        let prefix = 'bcast_';
        if (targetUserId) prefix = 'user_';
        else if (targetDepartment) prefix = `dept_${targetDepartment}_`;
        else if (targetStatus) prefix = `status_${targetStatus}_`;

        const baseAlertKey = prefix + Date.now();
        const alerts = users.map(user => ({
            user_id: user.id,
            title: title,
            body: body,
            trigger_at: triggerAt,
            type: 'broadcast',
            payload: payloadData,
            is_dispatched: false,
            alert_key: baseAlertKey + '_' + user.id
        }));

        // Insert in batches of 100 to avoid limits
        for (let i = 0; i < alerts.length; i += 100) {
            const batch = alerts.slice(i, i + 100);
            const { error: insertError } = await supabase
                .from('notifications')
                .insert(batch);

            if (insertError) throw insertError;
        }

        return new Response(JSON.stringify({
            success: true,
            message: `Broadcast scheduled for ${users.length} users at ${triggerAt}`
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }     
        });

    } catch (err: any) {
        return new Response(JSON.stringify({ error: err.message }), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }     
        });
    }
})
