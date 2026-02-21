-- ==========================================
-- EWUMATE SCHEMA MIGRATION: Schedule Exceptions
-- ==========================================

-- Table specifically for managing canceled classes and rescheduled makeup classes
CREATE TABLE IF NOT EXISTS public.schedule_exceptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    type TEXT NOT NULL, -- 'cancel' or 'makeup'
    date TEXT NOT NULL, -- Format: YYYY-MM-DD
    course_code TEXT NOT NULL,
    
    -- Fields specific to makeup classes
    course_name TEXT,
    start_time TEXT,
    end_time TEXT,
    room TEXT,
    
    -- Additional varied metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.schedule_exceptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own exceptions" ON public.schedule_exceptions;
CREATE POLICY "Users can view own exceptions" 
    ON public.schedule_exceptions FOR SELECT 
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own exceptions" ON public.schedule_exceptions;
CREATE POLICY "Users can insert own exceptions" 
    ON public.schedule_exceptions FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own exceptions" ON public.schedule_exceptions;
CREATE POLICY "Users can update own exceptions" 
    ON public.schedule_exceptions FOR UPDATE 
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own exceptions" ON public.schedule_exceptions;
CREATE POLICY "Users can delete own exceptions" 
    ON public.schedule_exceptions FOR DELETE 
    USING (auth.uid() = user_id);

