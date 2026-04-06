-- Table: semester_analytics
-- Roles: ['authenticated']
-- Command: SELECT
ALTER TABLE semester_analytics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read their own analytics" ON "semester_analytics"
FOR SELECT
TO authenticated
USING ((auth.uid() = user_id))
;
