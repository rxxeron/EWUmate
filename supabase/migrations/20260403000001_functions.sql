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
            id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
            event_date date NOT NULL,
            target_track text,
            created_at timestamptz DEFAULT now(),
            title text NOT NULL,
            type text
        );
        ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;
        GRANT SELECT ON TABLE public.%I TO anon, authenticated;
        GRANT ALL ON TABLE public.%I TO service_role;
    ', v_table, v_table, v_table, v_table);
    EXECUTE v_sql;

    BEGIN
        EXECUTE format('CREATE POLICY "public_read_%s" ON public.%I FOR SELECT USING (true);', p_semester_code, v_table);
    EXCEPTION WHEN duplicate_object THEN null; END;

    -- Attach automated scheduling trigger for semester switch
    BEGIN
        EXECUTE format('
            CREATE TRIGGER tr_schedule_switch_%1$s
            AFTER INSERT OR UPDATE ON public.%1$I
            FOR EACH ROW
            EXECUTE FUNCTION public.fn_auto_schedule_semester_switch();
        ', v_table);
    EXCEPTION WHEN duplicate_object THEN null; END;

    NOTIFY pgrst, 'reload schema';
END;
$function$;

;

CREATE OR REPLACE FUNCTION public.create_course_table(p_semester_code text)

 RETURNS void

 LANGUAGE plpgsql

 SECURITY DEFINER

AS $function$

DECLARE

    v_table text := 'courses_' || p_semester_code;

    v_sql text;

BEGIN

    v_sql := format('

        CREATE TABLE IF NOT EXISTS public.%I (

            id uuid DEFAULT gen_random_uuid() PRIMARY KEY,

            course_code text,

            original_code text,

            section_number text,

            faculty_initials text,

            capacity text,

            schedule_data jsonb,

            course_name text,

            credit_val numeric

        );

        ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;

        GRANT SELECT ON TABLE public.%I TO anon, authenticated;

        GRANT ALL ON TABLE public.%I TO service_role;

    ', v_table, v_table, v_table, v_table);

    EXECUTE v_sql;

    

    BEGIN

        EXECUTE format('CREATE POLICY "public_read_%s" ON public.%I FOR SELECT USING (true);', p_semester_code, v_table);

    EXCEPTION WHEN duplicate_object THEN null; END;



    
    -- Attach automated formatting trigger
    BEGIN
        EXECUTE format('
            CREATE TRIGGER tr_auto_fix_%1$s
            BEFORE INSERT OR UPDATE ON public.%2$I
            FOR EACH ROW
            EXECUTE FUNCTION fn_auto_fix_course();
        ', p_semester_code, v_table);
    EXCEPTION WHEN duplicate_object THEN null; END;

    
    -- Attach automated formatting trigger
    BEGIN
        EXECUTE format('
            CREATE TRIGGER tr_auto_fix_%1$s
            BEFORE INSERT OR UPDATE ON public.%2$I
            FOR EACH ROW
            EXECUTE FUNCTION fn_auto_fix_course();
        ', p_semester_code, v_table);
    EXCEPTION WHEN duplicate_object THEN null; END;

    NOTIFY pgrst, 'reload schema';

END;

$function$

;

CREATE OR REPLACE FUNCTION public.create_exam_table(p_semester_code text)

 RETURNS void

 LANGUAGE plpgsql

 SECURITY DEFINER

AS $function$

DECLARE

    v_table text := 'exams_' || p_semester_code;

    v_sql text;

BEGIN

    v_sql := format('

        CREATE TABLE IF NOT EXISTS public.%I (

            id serial primary key,

            course_code text,

            exam_date date,

            start_time time,

            end_time time,

            room text

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

CREATE OR REPLACE FUNCTION public.enable_rls_on_new_table()

 RETURNS event_trigger

 LANGUAGE plpgsql

 SECURITY DEFINER

AS $function$

DECLARE

    obj record;

BEGIN

    FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()

    LOOP

        IF obj.object_type = 'table' AND obj.schema_name = 'public' THEN

            EXECUTE format('ALTER TABLE %I.%I ENABLE ROW LEVEL SECURITY', obj.schema_name, obj.object_identity);

        END IF;

    END LOOP;

END;

$function$

;

CREATE OR REPLACE FUNCTION public.exec_sql(sql_query text)

 RETURNS void

 LANGUAGE plpgsql

 SECURITY DEFINER

AS $function$

            BEGIN

                EXECUTE sql_query;

            END;

            $function$

;

CREATE OR REPLACE FUNCTION public.fn_auto_fix_course()

 RETURNS trigger

 LANGUAGE plpgsql

AS $function$


BEGIN


    NEW.course_code := public.normalize_course_code(NEW.course_code);


    IF NEW.credit_val = 0 OR NEW.credit_val IS NULL THEN


        SELECT credit_val INTO NEW.credit_val FROM public.course_metadata WHERE code = NEW.course_code LIMIT 1;


    END IF;


    RETURN NEW;


END;


$function$

;

CREATE OR REPLACE FUNCTION public.get_grade_point(p_semester_code text, p_grade text)

 RETURNS numeric

 LANGUAGE plpgsql

AS $function$

DECLARE

    v_year int;

    v_season text;

    v_policy text;

    v_point numeric;

    v_clean_sem text;

    v_digit_str text;

BEGIN

    v_clean_sem := trim(p_semester_code);

    

    -- Extract year and season

    IF v_clean_sem LIKE '%_%' THEN

        v_year := COALESCE(NULLIF(split_part(v_clean_sem, '_', 2), ''), '0')::int;

        v_season := lower(split_part(v_clean_sem, '_', 1));

    ELSE

        -- Handle 'Spring2026' or similar

        -- Use \D to match non-digits

        v_digit_str := regexp_replace(v_clean_sem, '\D', '', 'g');

        

        IF v_digit_str IS NULL OR v_digit_str = '' THEN

            v_year := 0;

        ELSE

            v_year := v_digit_str::int;

        END IF;

        

        v_season := lower(regexp_replace(v_clean_sem, '[0-9]', '', 'g'));

    END IF;



    -- Determine Policy

    IF v_year = 0 THEN

        v_policy := 'modern'; 

    ELSIF v_year < 2023 THEN

        v_policy := 'legacy';

    ELSIF v_year = 2023 THEN

        IF v_season IN ('spring', 'summer') THEN

            v_policy := 'legacy';

        ELSE

            v_policy := 'modern';

        END IF;

    ELSE

        v_policy := 'modern';

    END IF;



    -- Fetch from grade_scale

    SELECT point INTO v_point FROM grade_scale WHERE grade = p_grade AND policy = v_policy LIMIT 1;

    

    RETURN COALESCE(v_point, 0.00);

END;

$function$

;

CREATE OR REPLACE FUNCTION public.handle_enrollment_sync()

 RETURNS trigger

 LANGUAGE plpgsql

 SECURITY DEFINER

AS $function$


DECLARE


  service_key TEXT := 'sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc'; -- Replace with your Service Role Key


  project_url TEXT := 'http://host.docker.internal:54321'; -- Replace with your Project URL


BEGIN


  PERFORM


    net.http_post(


      url := project_url || '/functions/v1/sync-schedule',


          'Authorization', 'Bearer ' || service_key,
          'apikey', 'sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc'


        'Content-Type', 'application/json',


        'Authorization', 'Bearer ' || service_key


      ),


      body := jsonb_build_object('user_id', COALESCE(NEW.user_id, OLD.user_id))


    );


  RETURN NEW;


END;


$function$

;

CREATE OR REPLACE FUNCTION public.handle_semester_switch_sync()

 RETURNS trigger

          'Authorization', 'Bearer ' || service_key,
          'apikey', 'sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc'

 SECURITY DEFINER

AS $function$


DECLARE


  service_key TEXT := 'sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';


  project_url TEXT := 'http://host.docker.internal:54321';


BEGIN


  -- Only trigger if the current_semester_code actually changed


  IF (OLD.current_semester_code IS DISTINCT FROM NEW.current_semester_code) THEN


    PERFORM


        'Authorization', 'Bearer sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc',
        'apikey', 'sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc'


        url := project_url || '/functions/v1/sync-semester-summary',


        headers := jsonb_build_object(


          'Content-Type', 'application/json',


          'Authorization', 'Bearer ' || service_key


        ),


        body := jsonb_build_object('track', NEW.track)


      );


  END IF;


  RETURN NEW;


END;


$function$

;

CREATE OR REPLACE FUNCTION public.normalize_course_code(p_code text)

 RETURNS text

 LANGUAGE plpgsql

 IMMUTABLE

AS $function$


BEGIN


    RETURN upper(regexp_replace(p_code, '\s+', '', 'g'));


END;


$function$

;

CREATE OR REPLACE FUNCTION public.promote_active_semester()

 RETURNS void

 LANGUAGE plpgsql

AS $function$

BEGIN

    UPDATE active_semester 

    SET current_semester_code = next_semester_code,

        updated_at = now()

    WHERE next_semester_code IS NOT NULL AND next_semester_code <> '';

END;

$function$

;

CREATE OR REPLACE FUNCTION public.shift_enrollments_by_track(p_track text, p_semester_code text, p_new_status text)

 RETURNS void

 LANGUAGE plpgsql

 SECURITY DEFINER

AS $function$

BEGIN

    UPDATE enrollments e

    SET status = p_new_status,

        grade = NULL

    FROM profiles p

    WHERE e.user_id = p.id

    AND p.track = p_track

    AND e.semester_code = p_semester_code

    AND e.status = 'upcoming';

END;

$function$

;

CREATE OR REPLACE FUNCTION public.sync_bulk_profile_enrollments(p_track text, p_semester text, p_user_id uuid DEFAULT NULL::uuid)

 RETURNS void

 LANGUAGE plpgsql

 SECURITY DEFINER

AS $function$

BEGIN

    WITH enrolled_agg AS (

        SELECT 

            e.user_id,

            array_agg(DISTINCT p_semester || '_' || e.course_code || '_N/A') as ids

        FROM enrollments e

        WHERE e.semester_code = p_semester

        AND (p_user_id IS NULL OR e.user_id = p_user_id)

        GROUP BY e.user_id

    )

    UPDATE profiles p

    SET enrolled_sections = COALESCE(ea.ids, '{}')

    FROM enrolled_agg ea

    WHERE p.id = ea.user_id

    AND p.track = p_track

    AND (p_user_id IS NULL OR p.id = p_user_id);

    

    -- Also clear for users with NO enrollments in the active semester

    IF p_user_id IS NULL THEN

        UPDATE profiles p

        SET enrolled_sections = '{}'

        WHERE p.track = p_track

        AND NOT EXISTS (

            SELECT 1 FROM enrollments e 

            WHERE e.user_id = p.id 

            AND e.semester_code = p_semester

        );

    ELSE

        UPDATE profiles p

        SET enrolled_sections = '{}'

        WHERE p.id = p_user_id

        AND NOT EXISTS (

            SELECT 1 FROM enrollments e 

            WHERE e.user_id = p.id 

            AND e.semester_code = p_semester

        );

    END IF;

END;

$function$

;

CREATE OR REPLACE FUNCTION public.sync_profile_enrolled_sections()

 RETURNS trigger

 LANGUAGE plpgsql

 SECURITY DEFINER

AS $function$

DECLARE

    user_track text;

    active_sem text;

    enrolled_ids text[];

BEGIN

    -- 1. Get user's track

    SELECT track INTO user_track FROM profiles WHERE id = COALESCE(NEW.user_id, OLD.user_id);

    IF user_track IS NULL THEN

        user_track := 'tri_semester'; -- Fallback

    END IF;



    -- 2. Get current active semester for that track

    SELECT initcap(replace(replace(lower(current_semester_code), ' ', ''), '_', ''))

    INTO active_sem

    FROM active_semester

    WHERE track = user_track::"public"."academic_track"; -- FIXED Type from track_type



    IF active_sem IS NULL THEN

        RETURN COALESCE(NEW, OLD);

    END IF;



    -- 3. Aggregate course references for the active semester

    -- Fix: Joining on course_code instead of code

    EXECUTE format(

        'SELECT array_agg(DISTINCT %L || %L || e.course_code || %L || COALESCE(c.section_number, %L)) ' ||

        'FROM enrollments e ' ||

        'LEFT JOIN %I c ON e.course_code = c.course_code ' || -- FIXED column name: course_code

        'WHERE e.user_id = %L AND initcap(replace(replace(lower(e.semester_code), %L, %L), %L, %L)) = %L',

        active_sem, '_', '_', 'N/A',

        'courses_' || lower(active_sem),

        COALESCE(NEW.user_id, OLD.user_id), ' ', '', '_', '', active_sem

    ) INTO enrolled_ids;



    -- 4. Update profiles

    UPDATE profiles

    SET enrolled_sections = COALESCE(enrolled_ids, '{}')

    WHERE id = COALESCE(NEW.user_id, OLD.user_id);



    RETURN COALESCE(NEW, OLD);

END;

$function$

;

CREATE OR REPLACE FUNCTION public.trg_notify_academic_sync()

 RETURNS trigger

 LANGUAGE plpgsql

AS $function$

    BEGIN

        PERFORM

          net.http_post(

            url := 'http://host.docker.internal:54321/functions/v1/sync-academic-stats',

            headers := jsonb_build_object(

              'Content-Type', 'application/json',

              'apikey', 'sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc',

              'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaXNzIjoic3VwYWJhc2UiLCJleHAiOjE4MDY4MDA4NTN9.4dAwywr34TDCWYbC8sHpyHXrc_whlZv_h4-S96qjMCg'

            ),

            body := jsonb_build_object('user_id', COALESCE(NEW.user_id, OLD.user_id))

          );

        RETURN NULL;

    END;

    $function$

;

CREATE OR REPLACE FUNCTION public.trg_notify_schedule_sync()

 RETURNS trigger

 LANGUAGE plpgsql

AS $function$

DECLARE

  payload JSONB;

BEGIN

  -- We always notify for the affected user

  payload := jsonb_build_object(

    'user_id', COALESCE(NEW.user_id, OLD.user_id)

  );



  PERFORM

    net.http_post(

      url := 'http://host.docker.internal:54321/functions/v1/sync-schedule',

      headers := jsonb_build_object(

        'Content-Type', 'application/json',

        'apikey', 'sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc',

        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaXNzIjoic3VwYWJhc2UiLCJleHAiOjE4MDY4MDA4NTN9.4dAwywr34TDCWYbC8sHpyHXrc_whlZv_h4-S96qjMCg'

      ),

      body := payload

    );

  

  RETURN NULL;

END;

$function$

;

CREATE OR REPLACE FUNCTION public.trg_shift_enrollment()

 RETURNS trigger

 LANGUAGE plpgsql

AS $function$

DECLARE

    v_credits numeric;

    v_gp numeric;

BEGIN

    -- Only shift if grade is updated from NULL to a value (or changed)

    -- AND NOT an ongoing/future placeholder (though usually they are NULL)

    IF NEW.grade IS NOT NULL AND (OLD.grade IS NULL OR OLD.grade != NEW.grade) THEN

        

        -- 1. Get Credits from course_metadata

        SELECT credit_val INTO v_credits FROM course_metadata WHERE code = NEW.course_code LIMIT 1;

        IF v_credits IS NULL THEN v_credits := 3.0; END IF; -- Default

        

        -- 2. Get Grade Point

        v_gp := get_grade_point(NEW.semester_code, NEW.grade);

        

        -- 3. Insert into completed_courses

        INSERT INTO completed_courses (user_id, course_code, semester_code, grade, credits, grade_point)

        VALUES (NEW.user_id, NEW.course_code, NEW.semester_code, NEW.grade, v_credits, v_gp)

        ON CONFLICT (user_id, course_code, semester_code) DO UPDATE 

        SET grade = EXCLUDED.grade, credits = EXCLUDED.credits, grade_point = EXCLUDED.grade_point;

        

        -- 4. Delete from enrollments

        DELETE FROM enrollments WHERE id = NEW.id;

        

        RETURN NULL; -- Row is deleted, so return NULL to signal completion of action

    END IF;

    

    RETURN NEW;

END;

$function$

;

CREATE OR REPLACE FUNCTION public.trigger_sync_schedule()

 RETURNS trigger

 LANGUAGE plpgsql

 SECURITY DEFINER

AS $function$

DECLARE

  host_header text;

  service_key text;

  dest_url text;

BEGIN

  -- 1. Try to get host from request headers (PostgREST)

  BEGIN

    host_header := current_setting('request.headers', true)::json->>'host';

  EXCEPTION WHEN OTHERS THEN

    host_header := 'jwygjihrbwxhehijldiz.supabase.co'; -- Fallback to project-specific host

  END;



  IF host_header IS NULL THEN

    host_header := 'jwygjihrbwxhehijldiz.supabase.co';

  END IF;



  dest_url := 'https://' || host_header || '/functions/v1/sync-schedule';



  -- 2. Trigger the Edge Function

  -- Note: service_role_key is usually available as a secret in vault or env

  PERFORM

    net.http_post(

      url := dest_url,

      headers := jsonb_build_object(

        'Content-Type', 'application/json',

        'Authorization', 'Bearer ' || COALESCE(current_setting('app.settings.service_role_key', true), 'SERVICE_ROLE_KEY_HERE')

      ),

      body := jsonb_build_object('user_id', COALESCE(NEW.user_id, OLD.user_id))

    );

  RETURN NEW;

END;

$function$

;

CREATE OR REPLACE FUNCTION public.trigger_track_sync()

 RETURNS trigger

 LANGUAGE plpgsql

 SECURITY DEFINER

AS $function$

DECLARE

  host_header text;

  dest_url text;

BEGIN

  -- 1. Try to get host from request headers (PostgREST)

  BEGIN

    host_header := current_setting('request.headers', true)::json->>'host';

  EXCEPTION WHEN OTHERS THEN

    host_header := 'jwygjihrbwxhehijldiz.supabase.co'; -- Fallback

  END;



  IF host_header IS NULL THEN

    host_header := 'jwygjihrbwxhehijldiz.supabase.co';

  END IF;



  -- 1. Trigger sync-schedule

  PERFORM

    net.http_post(

      url := 'http://host.docker.internal:54321/functions/v1/sync-schedule',

      headers := '{"Content-Type": "application/json", "Authorization": "Bearer sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6q"}'::jsonb,

      body := jsonb_build_object('track', NEW.track)

    );



  -- 2. Trigger sync-semester-meta (new)

  PERFORM

    net.http_post(

      url := 'http://host.docker.internal:54321/functions/v1/sync-semester-meta',

      headers := '{"Content-Type": "application/json", "Authorization": "Bearer sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6q"}'::jsonb,

      body := jsonb_build_object('record', jsonb_build_object('track', NEW.track, 'current_semester_code', NEW.current_semester_code))

    );



  -- 3. Trigger sync-profile-cache (new)

  PERFORM

    net.http_post(

      url := 'http://host.docker.internal:54321/functions/v1/sync-profile-cache',

      headers := '{"Content-Type": "application/json", "Authorization": "Bearer sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6q"}'::jsonb,

      body := jsonb_build_object('track', NEW.track)

    );



  RETURN NEW;

END;

$function$

;

CREATE OR REPLACE FUNCTION public.update_timestamp()

 RETURNS trigger

 LANGUAGE plpgsql

AS $function$


BEGIN


    NEW.updated_at = NOW();


    RETURN NEW;


END;


$function$

;

