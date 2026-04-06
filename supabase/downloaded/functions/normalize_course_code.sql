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
