-- Table: schedule_exceptions
-- Roles: ['public']
-- Command: DELETE
ALTER TABLE schedule_exceptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can delete their own exceptions" ON "schedule_exceptions"
FOR DELETE
TO public
USING ((auth.uid() = user_id))
;
