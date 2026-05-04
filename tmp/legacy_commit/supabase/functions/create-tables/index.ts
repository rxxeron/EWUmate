import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        const body = await req.json();
        const { semester_code } = body;

        if (!semester_code) {
            throw new Error("Missing semester_code");
        }

        const cleanSem = semester_code.replace(/\s+/g, '').replace(/_/g, '').toLowerCase();
        
        const courseTable = `courses_${cleanSem}`;
        const calendarTable = `calendar_${cleanSem}`;
        const calendarPhrmTable = `calendar_${cleanSem}_phrm_llb`;

        console.log(`Creating tables for semester: ${semester_code} (${cleanSem})`);

        // SQL to create tables
        const sql = `
            -- Courses Table
            CREATE TABLE IF NOT EXISTS public.${courseTable} (
                id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                course_code TEXT NOT NULL,
                original_code TEXT,
                course_name TEXT,
                section_number TEXT,
                faculty_initials TEXT,
                capacity TEXT,
                credit_val NUMERIC,
                schedule_data JSONB DEFAULT '[]'::jsonb,
                created_at TIMESTAMPTZ DEFAULT now()
            );

            -- Regular Calendar Table
            CREATE TABLE IF NOT EXISTS public.${calendarTable} (
                id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                event_date DATE NOT NULL,
                title TEXT NOT NULL,
                type TEXT,
                target_track TEXT DEFAULT 'tri_semester',
                created_at TIMESTAMPTZ DEFAULT now()
            );

            -- PHRM/LLB Calendar Table
            CREATE TABLE IF NOT EXISTS public.${calendarPhrmTable} (
                id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                event_date DATE NOT NULL,
                title TEXT NOT NULL,
                type TEXT,
                target_track TEXT DEFAULT 'bi_semester',
                created_at TIMESTAMPTZ DEFAULT now()
            );

            -- Grant permissions (Service Role & Authenticated)
            GRANT ALL ON TABLE public.${courseTable} TO service_role, postgres;
            GRANT SELECT ON TABLE public.${courseTable} TO authenticated;

            GRANT ALL ON TABLE public.${calendarTable} TO service_role, postgres;
            GRANT SELECT ON TABLE public.${calendarTable} TO authenticated;

            GRANT ALL ON TABLE public.${calendarPhrmTable} TO service_role, postgres;
            GRANT SELECT ON TABLE public.${calendarPhrmTable} TO authenticated;
        `;

        // Execute SQL via RPC or direct (Supabase RPC needs a custom function)
        // Since we can't easily run arbitrary SQL via the standard SDK without a 'exec_sql' RPC helper,
        // we assume 'exec_sql' exists or we use a fallback method if available in this environment.
        // For this specific system, let's try calling a common 'exec_sql' RPC if it exists.
        
        const { error: sqlError } = await supabase.rpc('exec_sql', { sql_query: sql });

        if (sqlError) {
            console.error("RPC exec_sql failed, trying direct postgres connection if available...");
            throw sqlError;
        }

        return new Response(JSON.stringify({ 
            success: true, 
            message: `Tables created for ${semester_code}`,
            tables: [courseTable, calendarTable, calendarPhrmTable]
        }), { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }, 
            status: 200 
        });

    } catch (error: any) {
        console.error("Create-Tables Error:", error);
        return new Response(JSON.stringify({ success: false, error: error.message }), { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }, 
            status: 400 
        });
    }
});
