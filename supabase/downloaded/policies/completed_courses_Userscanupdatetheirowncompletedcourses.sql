-- Table: completed_courses
-- Roles: ['public']
-- Command: UPDATE
ALTER TABLE completed_courses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can update their own completed courses" ON "completed_courses"
FOR UPDATE
TO public
USING ((auth.uid() = user_id))
;
