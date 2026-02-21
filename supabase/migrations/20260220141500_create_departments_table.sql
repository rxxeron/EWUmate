-- ==========================================
-- EWUMATE SCHEMA MIGRATION: Departments Table
-- ==========================================
-- Creates a dedicated table for University Departments and Programs
-- Replaces the legacy JSON structure in the metadata table.

-- 1. Create the departments table
CREATE TABLE IF NOT EXISTS public.departments (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    programs JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Insert the fallback/initial data
INSERT INTO public.departments (id, name, programs) VALUES
('cse', 'Dept. of CSE', '[{"id": "cse_eng", "name": "B.Sc. in Computer Science & Engineering"}, {"id": "cse_ice", "name": "B.Sc. in Information & Communication Engineering"}]'::jsonb),
('business', 'Dept. of Business', '[{"id": "bba", "name": "Bachelor of Business Administration"}, {"id": "mba", "name": "Master of Business Administration"}]'::jsonb),
('eee', 'Dept. of EEE', '[{"id": "eee", "name": "B.Sc. in Electrical & Electronic Engineering"}, {"id": "ete", "name": "B.Sc. in Electronics & Telecommunication Engineering"}]'::jsonb),
('pharmacy', 'Dept. of Pharmacy', '[{"id": "pha_b", "name": "Bachelor of Pharmacy"}, {"id": "pha_m", "name": "Master of Pharmacy"}]'::jsonb),
('english', 'Dept. of English', '[{"id": "eng_ba", "name": "B.A. in English"}]'::jsonb),
('sociology', 'Dept. of Sociology', '[{"id": "soc_bss", "name": "B.S.S. in Sociology"}]'::jsonb),
('economics', 'Dept. of Economics', '[{"id": "eco_bss", "name": "B.S.S. in Economics"}]'::jsonb),
('geb', 'Dept. of GEB', '[{"id": "geb", "name": "B.Sc. in Genetic Engineering & Biotechnology"}]'::jsonb)
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    programs = EXCLUDED.programs,
    updated_at = NOW();

-- 3. Enable RLS
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;

-- 4. Create Policies
DROP POLICY IF EXISTS "Public read departments" ON public.departments;
CREATE POLICY "Public read departments" ON public.departments FOR SELECT TO public USING (true);
