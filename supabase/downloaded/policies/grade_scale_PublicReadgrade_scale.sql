-- Table: grade_scale
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE grade_scale ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read grade_scale" ON "grade_scale"
FOR SELECT
TO public
USING (true)
;
