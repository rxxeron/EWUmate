-- Table: enrollments
-- Roles: ['authenticated']
-- Command: ALL
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
CREATE POLICY Users can manage their own enrollments ON enrollments
FOR ALL
TO authenticated
USING ((auth.uid() = user_id))
WITH CHECK ((auth.uid() = user_id))
;
