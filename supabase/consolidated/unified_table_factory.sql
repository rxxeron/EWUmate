-- Optimized Unified Table Factory
-- Replaces: create_advising_table, create_calendar_table, create_course_table, create_exam_table

CREATE OR REPLACE FUNCTION public.create_semester_table(p_type text, p_semester_code text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_table_name text;
    v_schema_query text;
BEGIN
    v_table_name := quote_ident(p_type || '_' || lower(regexp_replace(p_semester_code, '\s+', '', 'g')));

    -- 1. Check if table already exists
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = v_table_name) THEN
        RAISE NOTICE 'Table % already exists.', v_table_name;
        RETURN;
    END IF;

    -- 2. Define schema based on type
    CASE p_type
        WHEN 'courses' THEN
            v_schema_query := format('
                CREATE TABLE public.%I (
                    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
                    course_code text,
                    original_code text,
                    section_number text,
                    course_name text,
                    faculty_initials text,
                    capacity text,
                    credit_val numeric,
                    schedule_data jsonb,
                    created_at timestamptz DEFAULT now()
                )', v_table_name);
        WHEN 'calendar' THEN
            v_schema_query := format('
                CREATE TABLE public.%I (
                    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
                    event_date date NOT NULL,
                    title text NOT NULL,
                    type text,
                    target_track academic_track DEFAULT %L::academic_track,
                    created_at timestamptz DEFAULT now()
                )', v_table_name, 'tri_semester');
        WHEN 'exams' THEN
            v_schema_query := format('
                CREATE TABLE public.%I (
                    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
                    course_code text NOT NULL,
                    date date NOT NULL,
                    time_start text,
                    time_end text,
                    room text,
                    created_at timestamptz DEFAULT now()
                )', v_table_name);
        ELSE
            RAISE EXCEPTION 'Unknown table type: %', p_type;
    END CASE;

    -- 3. Execute creation
    EXECUTE v_schema_query;
    
    -- 4. Enable RLS and set default permissions
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', v_table_name);
    EXECUTE format('GRANT SELECT ON public.%I TO anon, authenticated', v_table_name);
    
    RAISE NOTICE 'Created table % successfully.', v_table_name;
END;
$function$
;
