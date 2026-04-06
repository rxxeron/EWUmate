-- Table: course_metadata
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE course_metadata ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view course metadata" ON "course_metadata"
FOR SELECT
TO public
USING (true)
;
