-- Table: feedbacks
-- Roles: ['authenticated']
-- Command: INSERT
ALTER TABLE feedbacks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable insert for authenticated users only" ON "feedbacks"
FOR INSERT
TO authenticated
WITH CHECK ((auth.uid() = user_id))
;
