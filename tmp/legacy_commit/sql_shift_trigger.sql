-- Function to get the grade point based on semester and grade
CREATE OR REPLACE FUNCTION get_grade_point(p_semester_code text, p_grade text) 
RETURNS numeric AS $$
DECLARE
    v_year int;
    v_season text;
    v_policy text;
    v_point numeric;
BEGIN
    -- Extract year (last 4 chars) and season
    -- Handles format like 'fall_2023' or 'Spring2026'
    IF p_semester_code LIKE '%_%' THEN
        v_year := (split_part(p_semester_code, '_', 2))::int;
        v_season := lower(split_part(p_semester_code, '_', 1));
    ELSE
        -- Handle 'Spring2026' format
        v_year := (regexp_replace(p_semester_code, '[^0-9]', '', 'g'))::int;
        v_season := lower(regexp_replace(p_semester_code, '[0-9]', '', 'g'));
    END IF;

    -- Determine Policy
    -- CUT-OFF: Fall 2023. Anything strictly before Fall 2023 is legacy.
    -- Order: spring < summer < fall
    IF v_year < 2023 THEN
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
$$ LANGUAGE plpgsql;

-- Trigger Function to move enrollments to completed_courses
CREATE OR REPLACE FUNCTION trg_shift_enrollment() 
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

-- Apply Trigger
DROP TRIGGER IF EXISTS enrollments_shift_trigger ON enrollments;
CREATE TRIGGER enrollments_shift_trigger
AFTER UPDATE ON enrollments
FOR EACH ROW
EXECUTE FUNCTION trg_shift_enrollment();
