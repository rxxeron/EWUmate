import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

    try {
        const { currentPassword, newPassword } = await req.json()
        const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
        const supabase = createClient(supabaseUrl, supabaseKey);

        // 1. Fetch current password (DB or Env)
        const { data: configData } = await supabase
            .from('config')
            .select('value')
            .eq('key', 'admin_password')
            .maybeSingle();

        let activePassword = configData?.value?.password || Deno.env.get('ADMIN_PASSWORD');

        if (!activePassword) {
            throw new Error("No admin password configured in system.");
        }

        // 2. Verify current password
        if (currentPassword !== activePassword) {
            return new Response(
                JSON.stringify({ error: 'Auth failed: Current password incorrect.' }),
                { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // 3. Update to new password
        const { error: updateError } = await supabase
            .from('config')
            .upsert({
                key: 'admin_password',
                value: { password: newPassword, last_updated: new Date().toISOString() }
            });

        if (updateError) throw updateError;

        return new Response(
            JSON.stringify({ success: true, message: "Admin password updated successfully." }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
