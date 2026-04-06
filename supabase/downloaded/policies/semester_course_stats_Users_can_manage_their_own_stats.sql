-- Table: semester_course_stats
-- Roles: ['authenticated']
-- Command: ALL
ALTER TABLE semester_course_stats ENABLE ROW LEVEL SECURITY;
CREATE POLICY Users can manage their own stats ON semester_course_stats
FOR ALL
TO authenticated
USING ((auth.uid() = user_id))
WITH CHECK ((auth.uid() = user_id))
;
