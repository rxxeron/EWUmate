-- Table: semester_summaries
-- Roles: ['authenticated']
-- Command: SELECT
ALTER TABLE semester_summaries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own summaries" ON "semester_summaries"
FOR SELECT
TO authenticated
USING ((auth.uid() = user_id))
;
