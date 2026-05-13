import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))

# 1. Update the RPC to include RLS for all future tables
rpc_sql = """
CREATE OR REPLACE FUNCTION public.create_course_table(p_semester_code text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Create the table with the enriched schema
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS public.courses_%I (
            id uuid NOT NULL DEFAULT gen_random_uuid(),
            course_code text NULL,
            original_code text NULL,
            section_number text NULL,
            faculty_initials text NULL,
            faculty_full_name text NULL,
            faculty_designation text NULL,
            capacity text NULL,
            schedule_data jsonb NULL,
            course_name text NULL,
            credit_val numeric NULL,
            dedicated_department text NULL,
            CONSTRAINT courses_%I_pkey PRIMARY KEY (id),
            CONSTRAINT courses_%I_course_code_section_number_key UNIQUE (course_code, section_number)
        );
    ', p_semester_code, p_semester_code, p_semester_code);

    -- Enable RLS automatically
    EXECUTE format('ALTER TABLE public.courses_%I ENABLE ROW LEVEL SECURITY;', p_semester_code);

    -- Add default Select policy (drop first if exists to be safe)
    EXECUTE format('DROP POLICY IF EXISTS "Allow public read" ON public.courses_%I;', p_semester_code);
    EXECUTE format('CREATE POLICY "Allow public read" ON public.courses_%I FOR SELECT USING (true);', p_semester_code);
    
    -- Grant necessary permissions
    EXECUTE format('GRANT SELECT ON public.courses_%I TO anon, authenticated;', p_semester_code);
    EXECUTE format('GRANT ALL ON public.courses_%I TO service_role;', p_semester_code);
END;
$function$;
"""

# 2. Apply to current tables immediately
patch_sql = """
-- Summer 2026
ALTER TABLE IF EXISTS public.courses_summer2026 ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read" ON public.courses_summer2026;
CREATE POLICY "Allow public read" ON public.courses_summer2026 FOR SELECT USING (true);

-- Fall 2026
ALTER TABLE IF EXISTS public.courses_fall2026 ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read" ON public.courses_fall2026;
CREATE POLICY "Allow public read" ON public.courses_fall2026 FOR SELECT USING (true);

-- Summer 2025
ALTER TABLE IF EXISTS public.courses_summer2025 ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read" ON public.courses_summer2025;
CREATE POLICY "Allow public read" ON public.courses_summer2025 FOR SELECT USING (true);
"""

print("Updating 'create_course_table' RPC with security defaults...")
sb.rpc("exec_sql", {"sql_query": rpc_sql}).execute()

print("Hardening existing course tables...")
sb.rpc("exec_sql", {"sql_query": patch_sql}).execute()

print("Security hardening complete for all academic course tables.")
