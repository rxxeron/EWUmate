-- Table: schedule_exceptions
-- Roles: ['authenticated']
-- Command: ALL
ALTER TABLE schedule_exceptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own exceptions" ON "schedule_exceptions"
FOR ALL
TO authenticated
USING ((auth.uid() = user_id))
WITH CHECK ((auth.uid() = user_id))
;
