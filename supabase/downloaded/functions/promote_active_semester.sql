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
