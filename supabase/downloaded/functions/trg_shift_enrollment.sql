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
