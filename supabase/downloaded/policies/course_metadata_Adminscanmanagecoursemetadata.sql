-- Table: course_metadata
-- Roles: ['public']
-- Command: ALL
ALTER TABLE course_metadata ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can manage course metadata" ON "course_metadata"
FOR ALL
TO public
USING ((auth.uid() IN ( SELECT admin_users.user_id
   FROM admin_users)))
;
