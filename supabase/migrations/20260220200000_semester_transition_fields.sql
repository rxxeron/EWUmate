-- Migration: Add fields for semester transition and enforced grade entry
-- 20260220200000_semester_transition_fields.sql

-- 1. Update active_semester table
ALTER TABLE public.active_semester 
ADD COLUMN IF NOT EXISTS grade_submission_start TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS grade_submission_deadline TIMESTAMP WITH TIME ZONE;

-- 2. Update profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS enrolled_sections_next TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS force_grade_entry BOOLEAN DEFAULT FALSE;

-- 3. Create a function to auto-assign exam dates to profile (to be called by app)
-- This is a helper that reads from exams_{semester_code} and updates a cache in profile
-- For now, we store this cache in a new column in profiles
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS exam_dates_cache JSONB DEFAULT '{}';

COMMENT ON COLUMN public.profiles.exam_dates_cache IS 'Stores a map of {pattern: {date, day}} for fast lookup in Semester Summary';
