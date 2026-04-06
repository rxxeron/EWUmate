-- Table: semester_course_marks
-- Roles: ['authenticated']
-- Command: ALL
ALTER TABLE semester_course_marks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own marks" ON "semester_course_marks"
FOR ALL
TO authenticated
USING ((auth.uid() = user_id))
WITH CHECK ((auth.uid() = user_id))
;
