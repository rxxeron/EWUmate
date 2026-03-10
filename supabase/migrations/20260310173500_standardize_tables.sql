-- Migration: Standardize Dynamic Tables and Promotion
-- This migration ensures all dynamically created tables (courses, exams, calendar) 
-- use lowercase names regardless of the input case, and updates promotion logic.

-- 1. Standardize Exam Table Creation
CREATE OR REPLACE FUNCTION public.create_exam_table(p_semester_code TEXT)
RETURNS void AS $$
DECLARE
    v_clean_code TEXT := lower(p_semester_code);
BEGIN
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS public.exams_%s (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            doc_id TEXT UNIQUE,
            code TEXT,
            section TEXT,
            day TEXT,
            date TEXT,
            time TEXT,
            room TEXT,
            semester TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
    ', v_clean_code);

    EXECUTE format('ALTER TABLE public.exams_%s ENABLE ROW LEVEL SECURITY;', v_clean_code);

    EXECUTE format('
        DROP POLICY IF EXISTS "Allow public read of exams_%s" ON public.exams_%s;
        CREATE POLICY "Allow public read of exams_%s" ON public.exams_%s FOR SELECT TO authenticated USING (true);
    ', v_clean_code, v_clean_code, v_clean_code, v_clean_code);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Standardize Calendar Table Creation
CREATE OR REPLACE FUNCTION public.create_calendar_table(p_semester_code TEXT)
RETURNS void AS $$
DECLARE
    v_clean_code TEXT := lower(p_semester_code);
BEGIN
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS public.calendar_%s (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            date TEXT,
            day TEXT,
            name TEXT,
            event TEXT,
            type TEXT,
            semester TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
    ', v_clean_code);

    EXECUTE format('ALTER TABLE public.calendar_%s ENABLE ROW LEVEL SECURITY;', v_clean_code);

    EXECUTE format('
        DROP POLICY IF EXISTS "Allow public read of calendar_%s" ON public.calendar_%s;
        CREATE POLICY "Allow public read of calendar_%s" ON public.calendar_%s FOR SELECT TO authenticated USING (true);
    ', v_clean_code, v_clean_code, v_clean_code, v_clean_code);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Standardize Course Table Creation (Adding if missing)
CREATE OR REPLACE FUNCTION public.create_course_table(p_semester_code TEXT)
RETURNS void AS $$
DECLARE
    v_clean_code TEXT := lower(p_semester_code);
BEGIN
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS public.courses_%s (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            doc_id TEXT UNIQUE,
            code TEXT,
            section TEXT,
            course_name TEXT,
            credits NUMERIC,
            capacity TEXT,
            type TEXT,
            semester TEXT,
            sessions JSONB,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
    ', v_clean_code);

    EXECUTE format('ALTER TABLE public.courses_%s ENABLE ROW LEVEL SECURITY;', v_clean_code);

    EXECUTE format('
        DROP POLICY IF EXISTS "Allow public read of courses_%s" ON public.courses_%s;
        CREATE POLICY "Allow public read of courses_%s" ON public.courses_%s FOR SELECT TO authenticated USING (true);
    ', v_clean_code, v_clean_code, v_clean_code, v_clean_code);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Standardize Advising Table Creation
CREATE OR REPLACE FUNCTION public.create_advising_table(p_semester_code TEXT)
RETURNS void AS $$
DECLARE
    v_clean_code TEXT := lower(p_semester_code);
BEGIN
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS public.advising_%s (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            doc_id TEXT UNIQUE,
            semester_id TEXT,
            slot_id TEXT,
            display_time TEXT,
            start_time TEXT,
            end_time TEXT,
            min_credits NUMERIC,
            max_credits NUMERIC,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
    ', v_clean_code);

    EXECUTE format('ALTER TABLE public.advising_%s ENABLE ROW LEVEL SECURITY;', v_clean_code);

    EXECUTE format('
        DROP POLICY IF EXISTS "Allow public read of advising_%s" ON public.advising_%s;
        CREATE POLICY "Allow public read of advising_%s" ON public.advising_%s FOR SELECT TO authenticated USING (true);
    ', v_clean_code, v_clean_code, v_clean_code, v_clean_code);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Updated Promotion Logic (Type-Aware)
CREATE OR REPLACE FUNCTION promote_active_semester()
RETURNS void AS $$
BEGIN
    -- This now works for ALL records (trimester and bi-semester)
    -- It only promotes rows that have a staged next_semester_code
    UPDATE public.active_semester
    SET 
        current_semester = next_semester,
        current_semester_code = next_semester_code,
        current_semester_start_date = upcoming_semester_start_date,
        next_semester = NULL,
        next_semester_code = NULL,
        upcoming_semester_start_date = NULL,
        switch_date = NULL,
        grade_submission_start = NULL,
        grade_submission_deadline = NULL,
        status = 'active',
        updated_at = NOW()
    WHERE next_semester_code IS NOT NULL 
      AND (switch_date IS NULL OR switch_date <= CURRENT_DATE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
