-- Table: grade_scale
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE grade_scale ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view grade scale" ON "grade_scale"
FOR SELECT
TO public
USING (true)
;
