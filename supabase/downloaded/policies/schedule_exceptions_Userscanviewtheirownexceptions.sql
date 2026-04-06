-- Table: schedule_exceptions
-- Roles: ['authenticated']
-- Command: SELECT
ALTER TABLE schedule_exceptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own exceptions" ON "schedule_exceptions"
FOR SELECT
TO authenticated
USING ((auth.uid() = user_id))
;
