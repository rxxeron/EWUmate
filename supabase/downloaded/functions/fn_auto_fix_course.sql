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
