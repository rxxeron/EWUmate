-- Table: courses_summer2026
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE courses_summer2026 ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public_read_summer2026" ON "courses_summer2026"
FOR SELECT
TO public
USING (true)
;
