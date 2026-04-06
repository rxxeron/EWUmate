-- Table: tasks
-- Roles: ['public']
-- Command: ALL
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own tasks" ON "tasks"
FOR ALL
TO public
USING ((auth.uid() = user_id))
WITH CHECK ((auth.uid() = user_id))
;
