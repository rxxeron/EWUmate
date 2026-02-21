import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPA_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPA_SERVICE_ROLE_KEY") ?? "";

serve(async (req) => {
    // We expect this to be called via POST, often with no body from pg_cron
    if (req.method !== 'POST') {
        return new Response('Method not allowed', { status: 405 });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const utcTimestamp = new Date().toISOString();
    console.log(`Alert Dispatcher started at ${utcTimestamp}`);

    try {
        // 1. Fetch pending alerts that are due
        // We use service role key to bypass RLS for scheduling
        const { data: pending, error: fetchError } = await supabase
            .from("scheduled_alerts")
            .select("*")
            .eq("is_dispatched", false)
            .lte("trigger_at", utcTimestamp);

        if (fetchError) {
            console.error("Error fetching pending alerts:", fetchError);
            return new Response(JSON.stringify({ error: fetchError.message }), { status: 500, headers: { "Content-Type": "application/json" } });
        }

        if (!pending || pending.length === 0) {
            console.log("No pending alerts to dispatch.");
            return new Response(JSON.stringify({ message: "No pending alerts to dispatch." }), { status: 200, headers: { "Content-Type": "application/json" } });
        }

        console.log(`Found ${pending.length} alerts to dispatch.`);

        let dispatchedCount = 0;
        const errors = [];

        // Process alerts sequentially to ensure reliable delivery
        for (const alert of pending) {
            try {
                // Move to live notifications table
                // This triggers the Supabase Realtime listener in the Flutter app
                const { error: insertError } = await supabase
                    .from("notifications")
                    .insert({
                        user_id: alert.user_id,
                        title: alert.title,
                        body: alert.body,
                        type: alert.type || 'system',
                        data: alert.metadata || {}
                    });

                if (insertError) throw insertError;

                // Mark as dispatched
                const { error: updateError } = await supabase
                    .from("scheduled_alerts")
                    .update({
                        is_dispatched: true,
                        dispatched_at: new Date().toISOString()
                    })
                    .eq("id", alert.id);

                if (updateError) throw updateError;

                console.log(`Successfully dispatched alert ${alert.id} to user ${alert.user_id}`);
                dispatchedCount++;
            } catch (err) {
                console.error(`Failed to dispatch alert ${alert.id}:`, err);
                errors.push({ id: alert.id, error: err });
            }
        }

        return new Response(JSON.stringify({
            message: `Successfully dispatched ${dispatchedCount} alerts.`,
            errors: errors.length > 0 ? errors : undefined
        }), { status: 200, headers: { "Content-Type": "application/json" } });

    } catch (err) {
        console.error("Unexpected error in alert dispatcher:", err);
        return new Response(JSON.stringify({ error: "Internal Server Error" }), { status: 500, headers: { "Content-Type": "application/json" } });
    }
});
