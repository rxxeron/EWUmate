-- Table: user_semester_states
-- Roles: ['authenticated']
-- Command: ALL
ALTER TABLE user_semester_states ENABLE ROW LEVEL SECURITY;
CREATE POLICY Users can manage their own states ON user_semester_states
FOR ALL
TO authenticated
USING ((auth.uid() = user_id))
WITH CHECK ((auth.uid() = user_id))
;
