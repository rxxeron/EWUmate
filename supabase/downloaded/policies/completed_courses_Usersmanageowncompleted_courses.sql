-- Table: completed_courses
-- Roles: ['public']
-- Command: ALL
ALTER TABLE completed_courses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own completed_courses" ON "completed_courses"
FOR ALL
TO public
USING (((auth.uid())::text = (user_id)::text))
WITH CHECK (((auth.uid())::text = (user_id)::text))
;
