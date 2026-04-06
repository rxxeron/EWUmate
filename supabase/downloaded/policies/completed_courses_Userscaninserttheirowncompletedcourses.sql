-- Table: completed_courses
-- Roles: ['public']
-- Command: INSERT
ALTER TABLE completed_courses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert their own completed courses" ON "completed_courses"
FOR INSERT
TO public
WITH CHECK ((auth.uid() = user_id))
;
