-- FULL SCHEMA RESET
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

-- Standard permissions
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO anon;
GRANT ALL ON SCHEMA public TO authenticated;
GRANT ALL ON SCHEMA public TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;

-- 1. Course Metadata (extracted from metadata/courses doc)
CREATE TABLE public.course_metadata (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    credits TEXT,
    credit_val INTEGER
);

-- 2. Metadata (for other docs like departments)
CREATE TABLE public.metadata (
    id TEXT PRIMARY KEY,
    data JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Unified Courses Table (Handles multiple semesters)
CREATE TABLE public.courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doc_id TEXT,
    semester TEXT NOT NULL,
    code TEXT NOT NULL,
    section TEXT,
    course_name TEXT,
    credits NUMERIC,
    capacity TEXT,
    type TEXT,
    sessions JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(semester, code, section, doc_id)
);

-- 4. Unified Calendar Table (Handles multiple semesters)
CREATE TABLE public.calendar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doc_id TEXT,
    semester TEXT NOT NULL,
    date TEXT,
    day TEXT,
    event TEXT,
    type TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Advising Schedules
CREATE TABLE public.advising_schedules (
    doc_id TEXT PRIMARY KEY,
    semester TEXT,
    slots JSONB DEFAULT '[]'::jsonb,
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Config
CREATE TABLE public.config (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. User Profiles
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    nickname TEXT,
    email TEXT,
    photo_url TEXT,
    department TEXT,
    program_id TEXT,
    admitted_semester TEXT,
    onboarding_status TEXT,
    scholarship_status TEXT,
    last_touch TIMESTAMPTZ,
    enrolled_sections JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Academic Data
CREATE TABLE public.academic_data (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    cgpa NUMERIC(3,2),
    total_credits_earned NUMERIC,
    remained_credits NUMERIC,
    semesters JSONB,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. User Schedules
CREATE TABLE public.user_schedules (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    weekly_template JSONB,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Semester Progress
CREATE TABLE public.semester_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    semester_code TEXT,
    summary JSONB,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, semester_code)
);

-- 11. Schedule Generations
CREATE TABLE public.schedule_generations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    semester TEXT,
    status TEXT,
    filters JSONB,
    courses JSONB,
    combinations JSONB,
    count INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE public.course_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advising_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.semester_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule_generations ENABLE ROW LEVEL SECURITY;

-- Read policies
CREATE POLICY "Allow public read - course_metadata" ON public.course_metadata FOR SELECT USING (true);
CREATE POLICY "Allow public read - metadata" ON public.metadata FOR SELECT USING (true);
CREATE POLICY "Allow public read - courses" ON public.courses FOR SELECT USING (true);
CREATE POLICY "Allow public read - calendar" ON public.calendar FOR SELECT USING (true);
CREATE POLICY "Allow public read - config" ON public.config FOR SELECT USING (true);

-- User policies
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can view own academic" ON public.academic_data FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view own schedules" ON public.user_schedules FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view own progress" ON public.semester_progress FOR SELECT USING (auth.uid() = user_id);

-- Service Role full access
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO service_role;