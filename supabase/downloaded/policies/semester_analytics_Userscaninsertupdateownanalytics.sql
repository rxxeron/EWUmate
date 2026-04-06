-- Table: semester_analytics
-- Roles: ['public']
-- Command: ALL
ALTER TABLE semester_analytics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert/update own analytics" ON "semester_analytics"
FOR ALL
TO public
USING ((auth.uid() = user_id))
WITH CHECK ((auth.uid() = user_id))
;
