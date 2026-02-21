-- RPC to dynamically create an exam table for a specific semester
CREATE OR REPLACE FUNCTION public.create_exam_table(p_semester_code TEXT)
RETURNS void AS $$
BEGIN
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS public.exams_%s (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            class_days TEXT,
            last_class_date TEXT,
            exam_day TEXT,
            exam_date TEXT,
            semester TEXT,
            type TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
    ', p_semester_code);

    -- Enable RLS
    EXECUTE format('ALTER TABLE public.exams_%s ENABLE ROW LEVEL SECURITY;', p_semester_code);

    -- Allow authenticated users to read exam data
    EXECUTE format('
        DROP POLICY IF EXISTS "Allow public read of exams_%s" ON public.exams_%s;
        CREATE POLICY "Allow public read of exams_%s" ON public.exams_%s FOR SELECT TO authenticated USING (true);
    ', p_semester_code, p_semester_code, p_semester_code, p_semester_code);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
