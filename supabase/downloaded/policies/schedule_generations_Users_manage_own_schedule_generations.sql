-- Table: schedule_generations
-- Roles: ['public']
-- Command: ALL
ALTER TABLE schedule_generations ENABLE ROW LEVEL SECURITY;
CREATE POLICY Users manage own schedule_generations ON schedule_generations
FOR ALL
TO public
USING (((auth.uid())::text = user_id))
WITH CHECK (((auth.uid())::text = user_id))
;
