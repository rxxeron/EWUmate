CREATE OR REPLACE FUNCTION public.get_grade_point(p_semester_code text, p_grade text)
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_year int;
    v_season text;
    v_policy text;
    v_point numeric;
    v_clean_sem text;
    v_digit_str text;
BEGIN
    v_clean_sem := trim(p_semester_code);
    
    -- Extract year and season
    IF v_clean_sem LIKE '%_%' THEN
        v_year := COALESCE(NULLIF(split_part(v_clean_sem, '_', 2), ''), '0')::int;
        v_season := lower(split_part(v_clean_sem, '_', 1));
    ELSE
        -- Handle 'Spring2026' or similar
        -- Use \D to match non-digits
        v_digit_str := regexp_replace(v_clean_sem, '\D', '', 'g');
        
        IF v_digit_str IS NULL OR v_digit_str = '' THEN
            v_year := 0;
        ELSE
            v_year := v_digit_str::int;
        END IF;
        
        v_season := lower(regexp_replace(v_clean_sem, '[0-9]', '', 'g'));
    END IF;

    -- Determine Policy
    IF v_year = 0 THEN
        v_policy := 'modern'; 
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
$function$
;
