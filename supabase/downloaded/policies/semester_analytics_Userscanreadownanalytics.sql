-- Table: semester_analytics
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE semester_analytics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own analytics" ON "semester_analytics"
FOR SELECT
TO public
USING ((auth.uid() = user_id))
;
