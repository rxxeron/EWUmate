-- Table: scholarship_policies
-- Roles: ['public']
-- Command: ALL
ALTER TABLE scholarship_policies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can manage scholarship policies" ON "scholarship_policies"
FOR ALL
TO public
USING ((auth.uid() IN ( SELECT admin_users.user_id
   FROM admin_users)))
;
