-- Table: courses_spring2026
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE courses_spring2026 ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read courses" ON "courses_spring2026"
FOR SELECT
TO public
USING (true)
;
