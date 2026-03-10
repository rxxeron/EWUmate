-- Migration: Standardize Advising Table Schema
-- Date: 2026-03-10

CREATE OR REPLACE FUNCTION public.create_advising_table(p_semester_code TEXT)
RETURNS void AS $$
DECLARE
    v_clean_code TEXT := lower(p_semester_code);
BEGIN
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS public.advising_%s (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            date TEXT,
            start_time TEXT,
            end_time TEXT,
            criteria_raw TEXT,
            min_credits NUMERIC,
            max_credits NUMERIC,
            allowed_departments TEXT[],
            semester TEXT,
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
