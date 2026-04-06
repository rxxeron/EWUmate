-- Table: programs
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE programs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read Programs" ON "programs"
FOR SELECT
TO public
USING (true)
;
