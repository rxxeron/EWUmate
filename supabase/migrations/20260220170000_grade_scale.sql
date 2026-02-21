-- ==========================================
-- EWUMATE SCHEMA MIGRATION: Universal Grade Scale
-- ==========================================

-- 1. Create Grade Scale Table
CREATE TABLE IF NOT EXISTS public.grade_scale (
    grade TEXT PRIMARY KEY,
    point NUMERIC NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Seed with University Standard Values (From Fall-2023 Policy)
INSERT INTO public.grade_scale (grade, point, description) VALUES
('A+', 4.00, '80% and above'),
('A', 3.75, '75% to less than 80%'),
('A-', 3.50, '70% to less than 75%'),
('B+', 3.25, '65% to less than 70%'),
('B', 3.00, '60% to less than 65%'),
('B-', 2.75, '55% to less than 60%'),
('C+', 2.50, '50% to less than 55%'),
('C', 2.25, '45% to less than 50%'),
('D', 2.00, '40% to less than 45%'),
('F', 0.00, 'Less than 40%'),
('F*', 0.00, 'Failure'),
('U', 0.00, 'Unsatisfactory'),
('I', 0.00, 'Incomplete'),
('P', 0.00, 'Pass'),
('R', 0.00, 'Repeat/Retake'),
('S', 0.00, 'Satisfactory (0 Credits for GPA)'),
('W', 0.00, 'Withdrawal'),
('Ongoing', 0.00, 'Currently In Progress')
ON CONFLICT (grade) DO UPDATE SET point = EXCLUDED.point, description = EXCLUDED.description;

-- 3. Enable RLS
ALTER TABLE public.grade_scale ENABLE ROW LEVEL SECURITY;

-- 4. Public Read Access
DROP POLICY IF EXISTS "Allow public read access on grade_scale" ON public.grade_scale;
CREATE POLICY "Allow public read access on grade_scale" ON public.grade_scale
    FOR SELECT USING (true);

-- 5. Trigger for Global Recalculation on Scale Change
CREATE OR REPLACE FUNCTION public.on_grade_scale_change()
RETURNS trigger AS $$
BEGIN
    PERFORM public.recalculate_all_academic_results();
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_recalculate_all_on_scale_change ON public.grade_scale;
CREATE TRIGGER trigger_recalculate_all_on_scale_change
    AFTER INSERT OR UPDATE OR DELETE
    ON public.grade_scale
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.on_grade_scale_change();
