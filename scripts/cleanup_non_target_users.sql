-- DATA CLEANUP SCRIPT
-- Purpose: Remove data for all users EXCEPT rhrakibulhasan279@gmail.com
-- Target User UUID: 374a09cd-c366-4eea-89cc-dbda99154c3e
-- Execution: Run this in the Supabase SQL Editor.

-- Start transaction to ensure atomicity
BEGIN;

-- 1. Requested Tables
DELETE FROM public.enrollments WHERE user_id != '374a09cd-c366-4eea-89cc-dbda99154c3e' OR user_id IS NULL;
DELETE FROM public.profiles WHERE id != '374a09cd-c366-4eea-89cc-dbda99154c3e';
DELETE FROM public.user_semester_states WHERE user_id != '374a09cd-c366-4eea-89cc-dbda99154c3e';
DELETE FROM public.tasks WHERE user_id != '374a09cd-c366-4eea-89cc-dbda99154c3e' OR user_id IS NULL;

-- 2. Additional User-Related Tables (Approved by user)
DELETE FROM public.completed_courses WHERE user_id != '374a09cd-c366-4eea-89cc-dbda99154c3e' OR user_id IS NULL;
DELETE FROM public.semester_summaries WHERE user_id != '374a09cd-c366-4eea-89cc-dbda99154c3e' OR user_id IS NULL;
DELETE FROM public.semester_analytics WHERE user_id != '374a09cd-c366-4eea-89cc-dbda99154c3e' OR user_id IS NULL;
DELETE FROM public.semester_course_marks WHERE user_id != '374a09cd-c366-4eea-89cc-dbda99154c3e' OR user_id IS NULL;
DELETE FROM public.semester_course_stats WHERE user_id != '374a09cd-c366-4eea-89cc-dbda99154c3e' OR user_id IS NULL;
DELETE FROM public.fcm_tokens WHERE user_id != '374a09cd-c366-4eea-89cc-dbda99154c3e' OR user_id IS NULL;
DELETE FROM public.feedbacks WHERE user_id != '374a09cd-c366-4eea-89cc-dbda99154c3e' OR user_id IS NULL;
DELETE FROM public.schedule_exceptions WHERE user_id != '374a09cd-c366-4eea-89cc-dbda99154c3e' OR user_id IS NULL;
DELETE FROM public.schedule_generations WHERE user_id != '374a09cd-c366-4eea-89cc-dbda99154c3e' OR user_id IS NULL;
DELETE FROM public.user_drafts WHERE user_id != '374a09cd-c366-4eea-89cc-dbda99154c3e' OR user_id IS NULL;
DELETE FROM public.notifications WHERE user_id != '374a09cd-c366-4eea-89cc-dbda99154c3e' AND user_id IS NOT NULL; -- Keep broadcasts (NULL user_id)

-- 3. Update target user onboarding status
UPDATE public.profiles 
SET onboarding_status = 'pending' 
WHERE id = '374a09cd-c366-4eea-89cc-dbda99154c3e';

-- Commit the transaction
COMMIT;
