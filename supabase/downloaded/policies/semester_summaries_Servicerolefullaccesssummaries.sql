-- Table: semester_summaries
-- Roles: ['service_role']
-- Command: ALL
ALTER TABLE semester_summaries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service role full access summaries" ON "semester_summaries"
FOR ALL
TO service_role
USING (true)
WITH CHECK (true)
;
