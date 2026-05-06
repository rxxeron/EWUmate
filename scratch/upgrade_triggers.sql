-- 1. Create Core Recalculation Functions
CREATE OR REPLACE FUNCTION recalculate_academic_stats(p_user_id uuid) RETURNS void AS $$
DECLARE
    v_rec record;
    v_cum_points numeric := 0.0;
    v_cum_credits numeric := 0.0;
    v_sem_points numeric;
    v_sem_credits numeric;
    v_tgpa numeric;
    v_cgpa numeric;
    v_total_completed_courses int := 0;
BEGIN
    FOR v_rec IN 
        SELECT 
            semester_code,
            COALESCE(SUM(CASE WHEN upper(grade) NOT IN ('W', 'I', 'P', 'S', 'U', 'R', 'ONGOING', 'PLANNED') THEN credits ELSE 0 END), 0) AS term_credits,
            COALESCE(SUM(CASE WHEN upper(grade) NOT IN ('W', 'I', 'P', 'S', 'U', 'R', 'ONGOING', 'PLANNED') THEN credits * grade_point ELSE 0 END), 0) AS term_points,
            COUNT(CASE WHEN upper(grade) NOT IN ('W', 'I', 'P', 'S', 'U', 'R', 'ONGOING', 'PLANNED') THEN 1 END) AS term_course_count,
            jsonb_agg(
                jsonb_build_object(
                    'code', course_code, 
                    'grade', grade, 
                    'credits', credits, 
                    'grade_point', grade_point
                )
            ) AS courses
        FROM public.completed_courses
        WHERE user_id = p_user_id
        GROUP BY semester_code
        ORDER BY 
            (regexp_replace(semester_code, '[^0-9]', '', 'g'))::int ASC,
            CASE lower(regexp_replace(semester_code, '[0-9]', '', 'g'))
                WHEN 'spring' THEN 1
                WHEN 'summer' THEN 2
                WHEN 'fall'   THEN 3
                ELSE 4
            END ASC
    LOOP
        v_sem_credits := v_rec.term_credits;
        v_sem_points := v_rec.term_points;
        v_total_completed_courses := v_total_completed_courses + v_rec.term_course_count;
        
        IF v_sem_credits > 0 THEN
            v_tgpa := v_sem_points / v_sem_credits;
        ELSE
            v_tgpa := 0.0;
        END IF;
        
        v_cum_points := v_cum_points + v_sem_points;
        v_cum_credits := v_cum_credits + v_sem_credits;
        
        IF v_cum_credits > 0 THEN
            v_cgpa := v_cum_points / v_cum_credits;
        ELSE
            v_cgpa := 0.0;
        END IF;

        INSERT INTO public.semester_summaries (
            user_id, semester_code, tgpa, cgpa, credits_earned, total_credits_earned, courses, updated_at
        )
        VALUES (
            p_user_id, v_rec.semester_code, v_tgpa, v_cgpa, v_sem_credits, v_cum_credits, v_rec.courses, NOW()
        )
        ON CONFLICT (user_id, semester_code) DO UPDATE SET
            tgpa = EXCLUDED.tgpa,
            cgpa = EXCLUDED.cgpa,
            credits_earned = EXCLUDED.credits_earned,
            total_credits_earned = EXCLUDED.total_credits_earned,
            courses = EXCLUDED.courses,
            updated_at = NOW();
    END LOOP;

    DELETE FROM public.semester_summaries 
    WHERE user_id = p_user_id 
      AND semester_code NOT IN (SELECT DISTINCT semester_code FROM public.completed_courses WHERE user_id = p_user_id);

    -- Final update to profiles
    UPDATE public.profiles
    SET cgpa = (CASE WHEN v_cum_credits > 0 THEN ROUND(v_cum_points / v_cum_credits, 2) ELSE 0 END),
        total_credits_earned = v_cum_credits,
        total_courses_completed = v_total_completed_courses,
        updated_at = NOW()
    WHERE id = p_user_id
      AND (
          cgpa IS DISTINCT FROM (CASE WHEN v_cum_credits > 0 THEN ROUND(v_cum_points / v_cum_credits, 2) ELSE 0 END)
          OR total_credits_earned IS DISTINCT FROM v_cum_credits
          OR total_courses_completed IS DISTINCT FROM v_total_completed_courses
      );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE OR REPLACE FUNCTION recalculate_enrollment_stats(p_user_id uuid) RETURNS void AS $$
DECLARE
    v_track text;
    v_current_sem text;
    v_next_sem text;
    v_current_sections uuid[];
    v_next_sections uuid[];
BEGIN
    SELECT track::text INTO v_track FROM public.profiles WHERE id = p_user_id;

    SELECT current_semester_code, next_semester_code INTO v_current_sem, v_next_sem
    FROM public.active_semester WHERE track::text = v_track LIMIT 1;

    SELECT array_remove(array_agg(section_id), NULL) INTO v_current_sections
    FROM public.enrollments
    WHERE user_id = p_user_id AND semester_code = v_current_sem AND status = 'enrolled' AND (grade IS NULL OR grade = '');

    SELECT array_remove(array_agg(section_id), NULL) INTO v_next_sections
    FROM public.enrollments
    WHERE user_id = p_user_id AND semester_code = v_next_sem AND status = 'upcoming' AND (grade IS NULL OR grade = '');

    UPDATE public.profiles
    SET enrolled_sections = COALESCE(v_current_sections, '{}'::uuid[]),
        enrolled_sections_next = COALESCE(v_next_sections, '{}'::uuid[]),
        updated_at = NOW()
    WHERE id = p_user_id
      AND (
          enrolled_sections IS DISTINCT FROM COALESCE(v_current_sections, '{}'::uuid[])
          OR enrolled_sections_next IS DISTINCT FROM COALESCE(v_next_sections, '{}'::uuid[])
      );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 2. Create Statement Router Functions
-- For completed_courses
CREATE OR REPLACE FUNCTION master_academic_sync_stmt_insert() RETURNS trigger AS $$
DECLARE
    v_user_id uuid;
BEGIN
    FOR v_user_id IN SELECT DISTINCT user_id FROM inserted_rows LOOP
        PERFORM recalculate_academic_stats(v_user_id);
    END LOOP;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION master_academic_sync_stmt_update() RETURNS trigger AS $$
DECLARE
    v_user_id uuid;
BEGIN
    FOR v_user_id IN 
        SELECT DISTINCT user_id FROM inserted_rows
        UNION
        SELECT DISTINCT user_id FROM deleted_rows
    LOOP
        PERFORM recalculate_academic_stats(v_user_id);
    END LOOP;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION master_academic_sync_stmt_delete() RETURNS trigger AS $$
DECLARE
    v_user_id uuid;
BEGIN
    FOR v_user_id IN SELECT DISTINCT user_id FROM deleted_rows LOOP
        PERFORM recalculate_academic_stats(v_user_id);
    END LOOP;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- For enrollments
CREATE OR REPLACE FUNCTION master_enrollment_sync_stmt_insert() RETURNS trigger AS $$
DECLARE
    v_user_id uuid;
BEGIN
    FOR v_user_id IN SELECT DISTINCT user_id FROM inserted_rows LOOP
        PERFORM recalculate_enrollment_stats(v_user_id);
    END LOOP;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION master_enrollment_sync_stmt_update() RETURNS trigger AS $$
DECLARE
    v_user_id uuid;
BEGIN
    FOR v_user_id IN 
        SELECT DISTINCT user_id FROM inserted_rows
        UNION
        SELECT DISTINCT user_id FROM deleted_rows
    LOOP
        PERFORM recalculate_enrollment_stats(v_user_id);
    END LOOP;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION master_enrollment_sync_stmt_delete() RETURNS trigger AS $$
DECLARE
    v_user_id uuid;
BEGIN
    FOR v_user_id IN SELECT DISTINCT user_id FROM deleted_rows LOOP
        PERFORM recalculate_enrollment_stats(v_user_id);
    END LOOP;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


-- 3. Drop Old Row-Level Triggers
DROP TRIGGER IF EXISTS trg_master_academic_sync ON public.completed_courses;
DROP TRIGGER IF EXISTS trg_master_enrollment_sync ON public.enrollments;

-- 4. Create New Statement-Level Triggers
-- completed_courses
CREATE TRIGGER trg_academic_sync_insert
AFTER INSERT ON public.completed_courses
REFERENCING NEW TABLE AS inserted_rows
FOR EACH STATEMENT EXECUTE FUNCTION master_academic_sync_stmt_insert();

CREATE TRIGGER trg_academic_sync_update
AFTER UPDATE ON public.completed_courses
REFERENCING NEW TABLE AS inserted_rows OLD TABLE AS deleted_rows
FOR EACH STATEMENT EXECUTE FUNCTION master_academic_sync_stmt_update();

CREATE TRIGGER trg_academic_sync_delete
AFTER DELETE ON public.completed_courses
REFERENCING OLD TABLE AS deleted_rows
FOR EACH STATEMENT EXECUTE FUNCTION master_academic_sync_stmt_delete();

-- enrollments
CREATE TRIGGER trg_enrollment_sync_insert
AFTER INSERT ON public.enrollments
REFERENCING NEW TABLE AS inserted_rows
FOR EACH STATEMENT EXECUTE FUNCTION master_enrollment_sync_stmt_insert();

CREATE TRIGGER trg_enrollment_sync_update
AFTER UPDATE ON public.enrollments
REFERENCING NEW TABLE AS inserted_rows OLD TABLE AS deleted_rows
FOR EACH STATEMENT EXECUTE FUNCTION master_enrollment_sync_stmt_update();

CREATE TRIGGER trg_enrollment_sync_delete
AFTER DELETE ON public.enrollments
REFERENCING OLD TABLE AS deleted_rows
FOR EACH STATEMENT EXECUTE FUNCTION master_enrollment_sync_stmt_delete();
