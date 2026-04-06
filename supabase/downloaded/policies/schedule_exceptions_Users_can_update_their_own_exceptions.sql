-- Table: schedule_exceptions
-- Roles: ['public']
-- Command: UPDATE
ALTER TABLE schedule_exceptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY Users can update their own exceptions ON schedule_exceptions
FOR UPDATE
TO public
USING ((auth.uid() = user_id))
;
