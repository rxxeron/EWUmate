-- Table: profiles
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read Profiles" ON "profiles"
FOR SELECT
TO public
USING (true)
;
