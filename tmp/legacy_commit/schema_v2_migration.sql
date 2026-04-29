-- 1. Create the new Relational table for graded courses
CREATE TABLE IF NOT EXISTS completed_courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    course_code TEXT NOT NULL,
    semester_code TEXT NOT NULL,
    grade TEXT NOT NULL,
    grade_point NUMERIC DEFAULT 0.0,
    credits NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Add indices for fast lookups
CREATE INDEX IF NOT EXISTS idx_completed_courses_user_id ON completed_courses(user_id);
CREATE INDEX IF NOT EXISTS idx_completed_courses_semester ON completed_courses(semester_code);

-- 3. Add the Cache column to profiles for instant UI loading
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS past_history JSONB DEFAULT '[]'::jsonb;

-- 4. Set RLS policies for completed_courses
ALTER TABLE completed_courses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own completed courses" 
ON completed_courses FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own completed courses" 
ON completed_courses FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own completed courses" 
ON completed_courses FOR UPDATE 
USING (auth.uid() = user_id);
