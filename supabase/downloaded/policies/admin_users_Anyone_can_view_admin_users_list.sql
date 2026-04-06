-- Table: admin_users
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY Anyone can view admin users list ON admin_users
FOR SELECT
TO public
USING (true)
;
