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
