-- Create tables for User Profiles and Data
-- These mirror the Firestore 'users' collection and its common sub-collections

-- 1. Profiles Table (Root User Data)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  nickname TEXT,
  photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Academic Data Table (Sub-collection equivalent)
CREATE TABLE IF NOT EXISTS academic_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cgpa NUMERIC(3,2),
  total_credits_earned NUMERIC DEFAULT 0,
  remained_credits NUMERIC DEFAULT 0,
  semesters JSONB DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 3. User Schedules Table (Sub-collection equivalent)
CREATE TABLE IF NOT EXISTS user_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  weekly_template JSONB DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 4. Semester Progress Table (Sub-collection equivalent)
CREATE TABLE IF NOT EXISTS semester_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  semester_code TEXT,
  summary JSONB DEFAULT '{}'::jsonb,
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, semester_code)
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE semester_progress ENABLE ROW LEVEL SECURITY;

-- Policies for Profiles (Users can read/write their own data)
CREATE POLICY "Users can view their own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Policies for Data Tables
CREATE POLICY "Users can view their own academic_data" ON academic_data FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own academic_data" ON academic_data FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own schedules" ON user_schedules FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own schedules" ON user_schedules FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own progress" ON semester_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own progress" ON semester_progress FOR UPDATE USING (auth.uid() = user_id);

-- Service Role full access
CREATE POLICY "Service role full access on profiles" ON profiles FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role full access on academic_data" ON academic_data FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role full access on user_schedules" ON user_schedules FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role full access on semester_progress" ON semester_progress FOR ALL USING (auth.role() = 'service_role');
