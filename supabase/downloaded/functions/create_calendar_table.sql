CREATE OR REPLACE FUNCTION public.create_calendar_table(p_semester_code text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_table text := 'calendar_' || p_semester_code;
    v_sql text;
BEGIN
    v_sql := format('
        CREATE TABLE IF NOT EXISTS public.%I (
            id serial primary key,
            event_name text,
            start_date date,
            end_date date,
            event_type text,
            remarks text
        );
        ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;
        GRANT SELECT ON TABLE public.%I TO anon, authenticated;
        GRANT ALL ON TABLE public.%I TO service_role;
    ', v_table, v_table, v_table, v_table);
    EXECUTE v_sql;

    BEGIN
        EXECUTE format('CREATE POLICY "public_read_%s" ON public.%I FOR SELECT USING (true);', p_semester_code, v_table);
    EXCEPTION WHEN duplicate_object THEN null; END;

    NOTIFY pgrst, 'reload schema';
END;
$function$
;
