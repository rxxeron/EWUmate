-- Table: profiles
-- Roles: ['public']
-- Command: ALL
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can sync own profile" ON "profiles"
FOR ALL
TO public
USING ((auth.uid() = id))
WITH CHECK ((auth.uid() = id))
;
