-- Function to get the grade point based on semester and grade
CREATE OR REPLACE FUNCTION get_grade_point(p_semester_code text, p_grade text) 
RETURNS numeric AS $$
DECLARE
    v_year int;
    v_season text;
    v_policy text;
    v_point numeric;
    v_clean_sem text;
BEGIN
    v_clean_sem := trim(p_semester_code);
    
    -- Extract year (last 4 chars) and season
    IF v_clean_sem LIKE '%_%' THEN
        v_year := (split_part(v_clean_sem, '_', 2))::int;
        v_season := lower(split_part(v_clean_sem, '_', 1));
    ELSE
        -- Handle 'Spring2026' or similar
        BEGIN
            v_year := (regexp_replace(v_clean_sem, '[^0-9]', '', 'g'))::int;
            v_season := lower(regexp_replace(v_clean_sem, '[0-9]', '', 'g'));
        EXCEPTION WHEN OTHERS THEN
            v_year := 0;
            v_season := '';
        END;
    END IF;

    -- Determine Policy
    IF v_year = 0 THEN
        v_policy := 'modern'; -- Default
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
$$ LANGUAGE plpgsql;
