-- Table: grade_scale
-- Roles: ['public']
-- Command: ALL
ALTER TABLE grade_scale ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can manage grade scale" ON "grade_scale"
FOR ALL
TO public
USING ((auth.uid() IN ( SELECT admin_users.user_id
   FROM admin_users)))
;
