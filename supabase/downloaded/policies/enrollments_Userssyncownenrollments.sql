-- Table: enrollments
-- Roles: ['public']
-- Command: ALL
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users sync own enrollments" ON "enrollments"
FOR ALL
TO public
USING ((auth.uid() = user_id))
;
