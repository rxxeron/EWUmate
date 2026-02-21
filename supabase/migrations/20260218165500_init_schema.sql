-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- RESET: Drop existing tables to ensure clean slate
-- Use CASCADE to remove dependent foreign keys
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS fcm_tokens CASCADE;
DROP TABLE IF EXISTS semester_progress CASCADE;
DROP TABLE IF EXISTS user_schedules CASCADE;
DROP TABLE IF EXISTS academic_data CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS calendar CASCADE;
DROP TABLE IF EXISTS advising_schedules CASCADE;
DROP TABLE IF EXISTS course_metadata CASCADE;
DROP TABLE IF EXISTS config CASCADE;


-- 1. CONFIG
CREATE TABLE config (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL
);

-- 2. METADATA (Course Catalog)
CREATE TABLE course_metadata (
    code TEXT PRIMARY KEY,
    name TEXT,
    credits TEXT,      -- Kept as TEXT to allow "3+1" format
    credit_val NUMERIC -- Numeric value for calculation (e.g. 4.0)
);

-- 3. ACADEMIC CALENDAR
CREATE TABLE calendar (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    semester TEXT NOT NULL,
    date TEXT,        -- "January 23"
    name TEXT,
    type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. COURSES (Offered Sections)
CREATE TABLE courses (
    -- We use a persistent Doc ID as PK to maintain compatibility and easy ingestion
    doc_id TEXT PRIMARY KEY, 
    semester TEXT NOT NULL,
    code TEXT NOT NULL,
    section TEXT,
    course_name TEXT,
    credits NUMERIC,  -- Specific course credit is usually a number
    capacity TEXT,    -- "35/40" is a string format in source
    type TEXT,
    sessions JSONB DEFAULT '[]'::jsonb, -- Array of {day, time, room...}
    faculty TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_courses_semester ON courses(semester);
CREATE INDEX idx_courses_code ON courses(code);

-- 5. USERS (Profiles)
-- Extends auth.users
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    student_id TEXT,
    full_name TEXT,
    nickname TEXT,
    email TEXT,
    department TEXT,
    program_id TEXT,
    admitted_semester TEXT,
    phone TEXT,
    photo_url TEXT,
    onboarding_status TEXT,
    scholarship_status TEXT,
    
    -- Course enrollment arrays
    enrolled_sections TEXT[] DEFAULT '{}', 
    enrolled_sections_next TEXT[] DEFAULT '{}',  -- For upcoming semester pre-enrollment
    
    -- Advising & Planning
    planner JSONB DEFAULT '{}'::jsonb,           -- Map of semester -> planned section IDs
    favorite_schedules JSONB DEFAULT '[]'::jsonb, -- Saved schedule combinations
    
    -- Semester transition
    force_grade_entry BOOLEAN DEFAULT FALSE,      -- Forces grade entry before semester switch
    exam_dates_cache JSONB DEFAULT '{}'::jsonb,   -- Cached exam date mappings
    
    last_touch TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. ACADEMIC DATA
-- Stores calculated results, GPA, history
CREATE TABLE academic_data (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    cgpa NUMERIC,             -- Float
    total_credits_earned NUMERIC, -- Float
    remained_credits NUMERIC,     -- Float
    program_name TEXT,
    
    -- Complex objects stored as JSONB
    semesters JSONB DEFAULT '[]'::jsonb, -- Array of semester result objects
    course_history JSONB DEFAULT '{}'::jsonb, -- Map of Semester -> {Course: Grade}
    completed_courses TEXT[] DEFAULT '{}', -- List of completed course codes
    
    last_updated TIMESTAMP WITH TIME ZONE
);

-- 7. USER SCHEDULES
-- Stores the personalized weekly schedule
CREATE TABLE user_schedules (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    semester TEXT, -- E.g., Spring2026
    
    weekly_template JSONB DEFAULT '{}'::jsonb, -- Map Day -> List of Classes
    day_swaps JSONB DEFAULT '[]'::jsonb,
    holidays JSONB DEFAULT '[]'::jsonb,
    
    last_updated TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (user_id, semester)
);

-- 8. SEMESTER PROGRESS
-- Stores prediction/tracking data for current semester
CREATE TABLE semester_progress (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    semester_code TEXT,
    
    summary JSONB DEFAULT '{}'::jsonb, -- Prediction summary object
    
    last_updated TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (user_id, semester_code)
);

-- 9. FCM TOKENS
CREATE TABLE fcm_tokens (
    token TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    platform TEXT,
    device_info JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. ADVISING SCHEDULES
CREATE TABLE advising_schedules (
    semester TEXT PRIMARY KEY,
    slots JSONB DEFAULT '[]'::jsonb,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. TASKS
CREATE TABLE tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    title TEXT,
    course_code TEXT,
    course_name TEXT,
    assign_date TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE,
    submission_type TEXT,
    type TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS POLICIES (Basic)

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE semester_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can view/edit their own
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Academic Data: Private to user
CREATE POLICY "Users can manage own academic data" ON academic_data FOR ALL USING (auth.uid() = user_id);

-- Schedules: Private to user
CREATE POLICY "Users can manage own schedules" ON user_schedules FOR ALL USING (auth.uid() = user_id);

-- Tasks: Private to user
CREATE POLICY "Users can manage own tasks" ON tasks FOR ALL USING (auth.uid() = user_id);

-- Tokens: Manage own
CREATE POLICY "Users can manage own tokens" ON fcm_tokens FOR ALL USING (auth.uid() = user_id);
