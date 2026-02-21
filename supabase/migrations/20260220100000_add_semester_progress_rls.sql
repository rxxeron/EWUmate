-- Add RLS policy for semester_progress table
-- This allows users to insert, update, delete, and view their own semester progress records

-- Ensure RLS is enabled (should already be from init_schema, but good to ensure)
ALTER TABLE public.semester_progress ENABLE ROW LEVEL SECURITY;

-- Grant users full access to manage their own progress records
DROP POLICY IF EXISTS "Users can manage own progress" ON public.semester_progress;
CREATE POLICY "Users can manage own progress" 
ON public.semester_progress 
FOR ALL 
USING (auth.uid() = user_id);
