-- Migration to create a central semesters table
CREATE TABLE IF NOT EXISTS public.semesters (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE, -- e.g. "Spring 2026"
    code TEXT NOT NULL UNIQUE, -- e.g. "spring2026"
    year INTEGER NOT NULL,
    season TEXT NOT NULL CHECK (season IN ('Spring', 'Summer', 'Fall')),
    is_historical BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for faster ordering
CREATE INDEX IF NOT EXISTS idx_semesters_year_season ON public.semesters (year DESC, season DESC);

-- Populate with data from Spring 2020 to Spring 2026
INSERT INTO public.semesters (name, code, year, season, is_historical) VALUES
('Spring 2020', 'spring2020', 2020, 'Spring', true),
('Summer 2020', 'summer2020', 2020, 'Summer', true),
('Fall 2020', 'fall2020', 2020, 'Fall', true),
('Spring 2021', 'spring2021', 2021, 'Spring', true),
('Summer 2021', 'summer2021', 2021, 'Summer', true),
('Fall 2021', 'fall2021', 2021, 'Fall', true),
('Spring 2022', 'spring2022', 2022, 'Spring', true),
('Summer 2022', 'summer2022', 2022, 'Summer', true),
('Fall 2022', 'fall2022', 2022, 'Fall', true),
('Spring 2023', 'spring2023', 2023, 'Spring', true),
('Summer 2023', 'summer2023', 2023, 'Summer', true),
('Fall 2023', 'fall2023', 2023, 'Fall', true),
('Spring 2024', 'spring2024', 2024, 'Spring', true),
('Summer 2024', 'summer2024', 2024, 'Summer', true),
('Fall 2024', 'fall2024', 2024, 'Fall', true),
('Spring 2025', 'spring2025', 2025, 'Spring', true),
('Summer 2025', 'summer2025', 2025, 'Summer', true),
('Fall 2025', 'fall2025', 2025, 'Fall', true),
('Spring 2026', 'spring2026', 2026, 'Spring', false)
ON CONFLICT (name) DO NOTHING;

-- Function to automatically add new semester when promoted or synced
CREATE OR REPLACE FUNCTION public.sync_semester_record()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.semesters (name, code, year, season, is_historical)
    VALUES (
        NEW.current_semester,
        NEW.current_semester_code,
        CAST(SUBSTRING(NEW.current_semester_code FROM '[0-9]+') AS INTEGER),
        CASE 
            WHEN NEW.current_semester ILIKE 'Spring%' THEN 'Spring'
            WHEN NEW.current_semester ILIKE 'Summer%' THEN 'Summer'
            WHEN NEW.current_semester ILIKE 'Fall%' THEN 'Fall'
        END,
        false
    )
    ON CONFLICT (name) DO UPDATE 
    SET is_historical = false; -- Ensure current one is not marked historical if it was added before
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to keep semesters table in sync with active_semester
DROP TRIGGER IF EXISTS tr_sync_semester_record ON public.active_semester;
CREATE TRIGGER tr_sync_semester_record
AFTER INSERT OR UPDATE OF current_semester ON public.active_semester
FOR EACH ROW EXECUTE FUNCTION public.sync_semester_record();

-- Update existing semesters to historical if they are not the current one in active_semester
DO $$
BEGIN
    UPDATE public.semesters 
    SET is_historical = true
    WHERE name NOT IN (SELECT current_semester FROM public.active_semester);
END $$;
