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
