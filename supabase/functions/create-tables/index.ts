import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import postgres from 'https://deno.land/x/postgresjs@v3.3.4/mod.js'

const SUPABASE_DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

const sqlQuery = `
-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT DEFAULT 'system',
    is_read BOOLEAN DEFAULT FALSE,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create scheduled_alerts table
CREATE TABLE IF NOT EXISTS public.scheduled_alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT,
    alert_key TEXT,
    trigger_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_dispatched BOOLEAN DEFAULT FALSE,
    dispatched_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, alert_key)
);

-- Enable RLS and Policies
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scheduled_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own notifications" ON public.notifications;
CREATE POLICY "Users can manage own notifications" ON public.notifications FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own scheduled_alerts" ON public.scheduled_alerts;
CREATE POLICY "Users can manage own scheduled_alerts" ON public.scheduled_alerts FOR ALL USING (auth.uid() = user_id);

NOTIFY pgrst, 'reload schema';
`;

serve(async (req) => {
    try {
        const sql = postgres(SUPABASE_DB_URL, { max: 1 })
        await sql.unsafe(sqlQuery)
        await sql.end()
        return new Response(JSON.stringify({ success: true, message: "Tables ensured." }), { headers: { "Content-Type": "application/json" } })
    } catch (err: any) {
        return new Response(JSON.stringify({ error: err.message }), { status: 500 })
    }
})
