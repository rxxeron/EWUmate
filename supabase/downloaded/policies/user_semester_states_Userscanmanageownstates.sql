-- Table: user_semester_states
-- Roles: ['public']
-- Command: ALL
ALTER TABLE user_semester_states ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own states" ON "user_semester_states"
FOR ALL
TO public
USING ((auth.uid() = user_id))
WITH CHECK ((auth.uid() = user_id))
;
