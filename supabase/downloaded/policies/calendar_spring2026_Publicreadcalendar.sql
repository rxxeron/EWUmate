-- Table: calendar_spring2026
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE calendar_spring2026 ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read calendar" ON "calendar_spring2026"
FOR SELECT
TO public
USING (true)
;
