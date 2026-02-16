-- Add INSERT/UPDATE/DELETE policies for authenticated users on user-owned tables
-- This is required for registration, onboarding, and normal app operations

-- Profiles: Users can create and update their own profile
CREATE POLICY "Users can insert own profile" ON public.profiles 
  FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles 
  FOR UPDATE USING (auth.uid() = id);

-- Academic Data: Users can insert and update their own academic data
CREATE POLICY "Users can insert own academic" ON public.academic_data 
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own academic" ON public.academic_data 
  FOR UPDATE USING (auth.uid() = user_id);

-- Semester Progress: Users can insert and update their progress
CREATE POLICY "Users can insert own progress" ON public.semester_progress 
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own progress" ON public.semester_progress 
  FOR UPDATE USING (auth.uid() = user_id);

-- Schedule Generations: Users can insert and view their schedules
CREATE POLICY "Users can view own generations" ON public.schedule_generations 
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own generations" ON public.schedule_generations 
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own generations" ON public.schedule_generations 
  FOR DELETE USING (auth.uid() = user_id);

-- User Schedules: Users can insert and update
CREATE POLICY "Users can insert own schedules" ON public.user_schedules 
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own schedules" ON public.user_schedules 
  FOR UPDATE USING (auth.uid() = user_id);

-- FCM Tokens (if table exists)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fcm_tokens') THEN
    EXECUTE 'CREATE POLICY "Users can manage own tokens" ON public.fcm_tokens FOR ALL USING (auth.uid() = user_id)';
  END IF;
END $$;
