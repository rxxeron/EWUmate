-- RPC to dynamically create a calendar table for a specific semester
CREATE OR REPLACE FUNCTION public.create_calendar_table(p_semester_code TEXT)
RETURNS void AS $$
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
    ', p_semester_code);

    -- Enable RLS
    EXECUTE format('ALTER TABLE public.calendar_%s ENABLE ROW LEVEL SECURITY;', p_semester_code);

    -- Allow authenticated users to read calendar data
    EXECUTE format('
        DROP POLICY IF EXISTS "Allow public read of calendar_%s" ON public.calendar_%s;
        CREATE POLICY "Allow public read of calendar_%s" ON public.calendar_%s FOR SELECT TO authenticated USING (true);
    ', p_semester_code, p_semester_code, p_semester_code, p_semester_code);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
