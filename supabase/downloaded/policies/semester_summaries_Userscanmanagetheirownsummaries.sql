-- Table: semester_summaries
-- Roles: ['authenticated']
-- Command: ALL
ALTER TABLE semester_summaries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own summaries" ON "semester_summaries"
FOR ALL
TO authenticated
USING ((auth.uid() = user_id))
WITH CHECK ((auth.uid() = user_id))
;
