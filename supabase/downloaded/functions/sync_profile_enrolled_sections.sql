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
