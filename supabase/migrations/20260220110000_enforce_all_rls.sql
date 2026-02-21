-- ==========================================
-- EWUMATE SCHEMA MIGRATION: 20260220_enforce_all_rls
-- ==========================================
-- Comprehensive Row Level Security (RLS) enforcement.
-- Ensures that EVERY table in the database has RLS enabled
-- and appropriate access policies defined.

-- ==========================================
-- 1. ENABLE RLS ON ALL TABLES
-- ==========================================
ALTER TABLE IF EXISTS public.config ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.course_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.academic_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.semester_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.advising_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.active_semester ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.schedule_generations ENABLE ROW LEVEL SECURITY;


-- ==========================================
-- 2. DROP EXISTING POLICIES TO PREVENT DUPLICATES
-- ==========================================
-- We use a DO block to drop policies safely if they exist
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
    END LOOP;
END $$;


-- ==========================================
-- 3. CREATE NEW SECURE POLICIES
-- ==========================================

-- --- GLOBAL READ-ONLY TABLES (Publicly Accessible) ---
-- Users need to see configurations, course catalogs, academic calendar, and available courses

-- config
CREATE POLICY "Public read config" ON public.config FOR SELECT TO public USING (true);

-- course_metadata
CREATE POLICY "Public read course_metadata" ON public.course_metadata FOR SELECT TO public USING (true);

-- calendar
CREATE POLICY "Public read calendar" ON public.calendar FOR SELECT TO public USING (true);

-- courses
CREATE POLICY "Public read courses" ON public.courses FOR SELECT TO public USING (true);

-- advising_schedules
CREATE POLICY "Public read advising_schedules" ON public.advising_schedules FOR SELECT TO public USING (true);

-- active_semester
CREATE POLICY "Public read active_semester" ON public.active_semester FOR SELECT TO public USING (true);


-- --- USER PRIVATE DATA TABLES (Authenticated Only) ---
-- Users can only insert, select, update, and delete their own rows matching their auth.uid()

-- profiles (Users can view all public profiles, but only edit their own)
CREATE POLICY "Public read profiles" ON public.profiles FOR SELECT TO public USING (true);
CREATE POLICY "Users manage own profiles" ON public.profiles FOR ALL TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- academic_data
CREATE POLICY "Users manage own academic_data" ON public.academic_data FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- user_schedules
CREATE POLICY "Users manage own schedules" ON public.user_schedules FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- semester_progress (This fixes the previous PostgresException)
CREATE POLICY "Users manage own semester_progress" ON public.semester_progress FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- fcm_tokens
CREATE POLICY "Users manage own fcm_tokens" ON public.fcm_tokens FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- tasks
CREATE POLICY "Users manage own tasks" ON public.tasks FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- schedule_generations
CREATE POLICY "Users manage own schedule_generations" ON public.schedule_generations FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);


-- ==========================================
-- 4. SERVICE ROLE (Admin) BYPASS
-- ==========================================
-- The Supabase service role (used by backend Azure Functions and webhooks) 
-- inherently bypasses RLS in Postgres, so explicit policies are not strictly 
-- required for it, but enabling RLS ensures client connections (anon/authenticated) 
-- are strictly controlled.
