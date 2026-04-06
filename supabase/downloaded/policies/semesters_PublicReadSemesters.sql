-- Table: semesters
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE semesters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read Semesters" ON "semesters"
FOR SELECT
TO public
USING (true)
;
