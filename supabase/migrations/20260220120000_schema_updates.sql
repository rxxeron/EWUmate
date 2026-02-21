-- ==========================================
-- EWUMATE SCHEMA MIGRATION: ADVISING & TRANSITION
-- ==========================================
-- Run this in your Supabase SQL Editor to ensure your database 
-- is compatible with the new Manual Planning and Automated Generator.

-- 1. Profiles Table Expansions
-- Adds support for saving manual plans and favorite schedule combinations
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS planner JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS favorite_schedules JSONB DEFAULT '[]'::jsonb;

-- 2. Academic Data Expansion
-- Ensures numeric types for credits and structured list for semester history
ALTER TABLE public.academic_data 
ADD COLUMN IF NOT EXISTS total_credits_earned NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS remained_credits NUMERIC DEFAULT 148,
ADD COLUMN IF NOT EXISTS semesters JSONB DEFAULT '[]'::jsonb;

-- 3. Active Semester Configuration (Single Source of Truth)
-- Stores which semesters are currently active and when transition should happen
CREATE TABLE IF NOT EXISTS public.active_semester (
    id SERIAL PRIMARY KEY,
    is_active BOOLEAN DEFAULT false,
    current_semester TEXT,
    current_semester_code TEXT,
    next_semester TEXT,
    next_semester_code TEXT,
    advising_start_date TEXT,
    switch_date TEXT,
    status TEXT DEFAULT 'active',
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure there is at least one row for the Function to update
INSERT INTO public.active_semester (
    is_active, current_semester, current_semester_code, 
    next_semester, next_semester_code, advising_start_date, switch_date, status
)
SELECT 
    true, 'Spring 2026', 'Spring2026', 
    'Summer 2026', 'Summer2026', '2026-04-14', '2026-06-01', 'active'
WHERE NOT EXISTS (SELECT 1 FROM public.active_semester);

-- 4. Schedule Generations (Generator Result Persistence)
CREATE TABLE IF NOT EXISTS public.schedule_generations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    semester TEXT,
    courses JSONB DEFAULT '[]'::jsonb,
    filters JSONB DEFAULT '{}'::jsonb,
    combinations JSONB DEFAULT '[]'::jsonb,
    status TEXT DEFAULT 'pending',
    count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS (Recommended)
ALTER TABLE public.active_semester ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule_generations ENABLE ROW LEVEL SECURITY;

-- Basic Policies (Allow authenticated users to read config)
DROP POLICY IF EXISTS "Allow public read of active semester" ON public.active_semester;
CREATE POLICY "Allow public read of active semester" ON public.active_semester FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Users can manage their own generations" ON public.schedule_generations;
CREATE POLICY "Users can manage their own generations" ON public.schedule_generations FOR ALL TO authenticated USING (auth.uid() = user_id);
