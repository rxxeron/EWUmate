-- 1. Add semester_type to active_semester
ALTER TABLE public.active_semester ADD COLUMN IF NOT EXISTS semester_type TEXT;

-- 1b. Drop old "single_active" constraint if it exists 
-- (This was preventing multiple department tracks from being active)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'single_active') THEN
        ALTER TABLE public.active_semester DROP CONSTRAINT single_active;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'unique_semester_type'
    ) THEN
        ALTER TABLE public.active_semester ADD CONSTRAINT unique_semester_type UNIQUE (semester_type);
    END IF;
END
$$;

-- 2. Add semester_type to departments
ALTER TABLE public.departments ADD COLUMN IF NOT EXISTS semester_type TEXT DEFAULT 'tri';

-- 3. Seed/Update existing data
-- Standard University (ID 1)
UPDATE public.active_semester SET semester_type = 'tri' WHERE id = 1;

-- Add semester_type to profiles for faster access
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS semester_type TEXT;

-- Index for better query performance
CREATE INDEX IF NOT EXISTS idx_active_semester_type ON public.active_semester(semester_type);
CREATE INDEX IF NOT EXISTS idx_profiles_semester_type ON public.profiles(semester_type);

-- Pharmacy/Law (ID 2)
-- If row 2 doesn't exist, we create/update it (providing required non-null fields)
INSERT INTO public.active_semester (id, semester_type, current_semester, current_semester_code, status, is_active) 
VALUES (2, 'bi', 'Spring 2026', 'spring2026', 'active', true) 
ON CONFLICT (id) DO UPDATE SET semester_type = 'bi';

INSERT INTO public.active_semester (id, semester_type, current_semester, current_semester_code, status, is_active) 
VALUES (1, 'tri', 'Spring 2026', 'spring2026', 'active', true) 
ON CONFLICT (id) DO UPDATE SET semester_type = 'tri';

-- Update departments logic
-- Add Law department if missing
INSERT INTO public.departments (id, name, programs, semester_type)
VALUES ('law', 'Dept. of Law', '[{"id": "llb", "name": "Bachelor of Laws"}]'::jsonb, 'bi')
ON CONFLICT (id) DO UPDATE SET semester_type = 'bi';

UPDATE public.departments SET semester_type = 'bi' WHERE id IN ('pharmacy', 'law');
UPDATE public.departments SET semester_type = 'tri' WHERE semester_type IS NULL;
