-- Unified Sync Engine
-- Consolidates enrollment-to-profile synchronization logic

-- 1. Optimized Internal Sync Logger (Optional, for debugging)
CREATE OR REPLACE FUNCTION public.log_sync_event(p_user_id uuid, p_event text)
RETURNS void AS $$
BEGIN
    -- This could log to a table if needed, for now just a notice
    RAISE NOTICE 'Sync Event for %: %', p_user_id, p_event;
END;
$$ LANGUAGE plpgsql;

-- 2. Core Enrollment Sync Function (Unified Trigger Function)
CREATE OR REPLACE FUNCTION public.fn_sync_enrollments()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_active_sem text;
    v_user_track text;
    v_enrolled_ids text[];
    v_table_name text;
    v_table_exists boolean;
    v_user_id uuid;
BEGIN
    v_user_id := COALESCE(NEW.user_id, OLD.user_id);

    -- Get user track
    SELECT track INTO v_user_track FROM public.profiles WHERE id = v_user_id;
    IF v_user_track IS NULL THEN v_user_track := 'tri_semester'; END IF;

    -- Get active semester code for this track
    SELECT initcap(replace(replace(lower(current_semester_code), ' ', ''), '_', ''))
    INTO v_active_sem
    FROM public.active_semester
    WHERE track = v_user_track::public.academic_track;

    IF v_active_sem IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    -- Update GPA/Grade Points if grade changed
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND NEW.grade IS NOT NULL THEN
        NEW.grade_points := public.get_grade_point(COALESCE(NEW.semester_code, v_active_sem), NEW.grade);
    END IF;

    -- Aggregate enrolled sections for the active semester
    v_table_name := 'courses_' || lower(v_active_sem);
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = quote_ident(v_table_name)
    ) INTO v_table_exists;

    IF v_table_exists THEN
        EXECUTE format(
            'SELECT array_agg(DISTINCT %L || %L || e.course_code || %L || COALESCE(c.section_number, %L)) ' ||
            'FROM public.enrollments e ' ||
            'LEFT JOIN public.%I c ON e.course_code = c.course_code ' ||
            'WHERE e.user_id = %L AND initcap(replace(replace(lower(e.semester_code), %L, %L), %L, %L)) = %L',
            v_active_sem, '_', '_', 'N/A',
            v_table_name,
            v_user_id, ' ', '', '_', '', v_active_sem
        ) INTO v_enrolled_ids;
    ELSE
        SELECT array_agg(DISTINCT v_active_sem || '_' || e.course_code || '_N/A')
        INTO v_enrolled_ids
        FROM public.enrollments e
        WHERE e.user_id = v_user_id 
          AND initcap(replace(replace(lower(e.semester_code), ' ', ''), '_', '')) = v_active_sem;
    END IF;

    -- Update profile fields
    UPDATE public.profiles
    SET 
        enrolled_sections = COALESCE(v_enrolled_ids, '{}'),
        updated_at = now()
    WHERE id = v_user_id;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Enrollment sync failed for user %: %', v_user_id, SQLERRM;
    RETURN COALESCE(NEW, OLD);
END;
$function$
;

-- 3. Bulk Sync Utility (For administrative use)
CREATE OR REPLACE FUNCTION public.sync_all_profiles(p_track text DEFAULT NULL)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT id, track FROM public.profiles WHERE (p_track IS NULL OR track = p_track) LOOP
        -- Triggers fn_sync_enrollments via a dummy update or manual call logic
        -- Better: Just update all profiles directly in one query if possible (Optimization)
        -- For now, we'll keep it simple by triggering the logic per user.
        UPDATE public.enrollments SET updated_at = now() WHERE user_id = r.id;
    END LOOP;
END;
$function$
;
