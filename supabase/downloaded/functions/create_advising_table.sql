CREATE OR REPLACE FUNCTION public.create_advising_table(p_semester_code text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_table text := 'advising_' || p_semester_code;
    v_sql text;
BEGIN
    v_sql := format('
        CREATE TABLE IF NOT EXISTS public.%I (
            id serial primary key,
            student_id text,
            advised_courses jsonb,
            advising_time timestamp
        );
        ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;
        GRANT ALL ON TABLE public.%I TO anon, authenticated, service_role;
    ', v_table, v_table, v_table);
    EXECUTE v_sql;

    BEGIN
        EXECUTE format('CREATE POLICY "all_access_%s" ON public.%I FOR ALL USING (true) WITH CHECK (true);', p_semester_code, v_table);
    EXCEPTION WHEN duplicate_object THEN null; END;

    NOTIFY pgrst, 'reload schema';
END;
$function$
;
