import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import postgres from 'https://deno.land/x/postgresjs@v3.3.4/mod.js'

const SUPABASE_DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

serve(async (req) => {
    try {
        const sql = postgres(SUPABASE_DB_URL, { max: 1 })

        // 1. Force update tomorrow's alerts to be due now
        await sql`
            UPDATE public.scheduled_alerts 
            SET trigger_at = now() - interval '1 minute'
            WHERE trigger_at >= '2026-02-22 00:00:00+00' 
              AND trigger_at < '2026-02-23 00:00:00+00'
              AND is_dispatched = false
        `

        // 2. Invoke dispatcher logic directly (or let cron handle it, but we want it NOW)
        // I'll just run the insert part manually here for speed
        await sql`
            INSERT INTO public.notifications (user_id, title, body, type, data)
            SELECT user_id, title, body, COALESCE(type, 'system'), 
                   jsonb_build_object('alert_key', alert_key, 'trigger_at', trigger_at)
            FROM public.scheduled_alerts
            WHERE is_dispatched = false AND trigger_at <= now()
        `

        await sql`
            UPDATE public.scheduled_alerts
            SET is_dispatched = true, dispatched_at = now()
            WHERE is_dispatched = false AND trigger_at <= now()
        `

        await sql.end()
        return new Response(JSON.stringify({ success: true, message: "Tomorrow's schedule dispatched to app." }), { headers: { "Content-Type": "application/json" } })
    } catch (err: any) {
        return new Response(JSON.stringify({ error: err.message }), { status: 500 })
    }
})
