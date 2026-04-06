-- Table: completed_courses
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE completed_courses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own completed courses" ON "completed_courses"
FOR SELECT
TO public
USING ((auth.uid() = user_id))
;
