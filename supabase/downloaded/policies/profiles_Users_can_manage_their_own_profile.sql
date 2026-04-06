-- Table: profiles
-- Roles: ['authenticated']
-- Command: ALL
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY Users can manage their own profile ON profiles
FOR ALL
TO authenticated
USING ((auth.uid() = id))
WITH CHECK ((auth.uid() = id))
;
