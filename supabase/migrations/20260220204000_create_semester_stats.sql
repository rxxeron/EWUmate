-- Create table for tracking semester-specific course stats
CREATE TABLE IF NOT EXISTS public.semester_course_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    semester TEXT NOT NULL,
    course_code TEXT NOT NULL,
    marks_obtained DOUBLE PRECISION DEFAULT 0.0,
    grade_goal TEXT,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, semester, course_code)
);

-- Enable RLS
ALTER TABLE public.semester_course_stats ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can manage their own semester stats"
ON public.semester_course_stats FOR ALL
USING (auth.uid() = user_id);
