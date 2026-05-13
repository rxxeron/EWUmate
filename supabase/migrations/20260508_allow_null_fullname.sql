-- Migration: Allow NULL values in profiles.full_name
-- Created: 2026-05-08

ALTER TABLE public.profiles 
ALTER COLUMN full_name DROP NOT NULL;

-- Also ensure nickname and student_id remain nullable (they already are, but for clarity)
ALTER TABLE public.profiles 
ALTER COLUMN nickname DROP NOT NULL,
ALTER COLUMN student_id DROP NOT NULL;

-- Note: We keep the NOT NULL constraint on 'id' as it is the primary key.
