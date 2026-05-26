-- 1. Add office_room column to public.faculty_master
ALTER TABLE public.faculty_master 
ADD COLUMN IF NOT EXISTS office_room TEXT;

-- 2. Add semester_code and office_room columns to public.faculty_office_hours
ALTER TABLE public.faculty_office_hours 
ADD COLUMN IF NOT EXISTS semester_code TEXT NOT NULL DEFAULT 'Summer 2026',
ADD COLUMN IF NOT EXISTS office_room TEXT;

-- 3. Index semester_code for high performance queries
CREATE INDEX IF NOT EXISTS idx_foh_semester ON public.faculty_office_hours(semester_code);
