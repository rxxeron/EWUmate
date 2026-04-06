-- Table: active_semester
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE active_semester ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read active_semester" ON "active_semester"
FOR SELECT
TO public
USING (true)
;
