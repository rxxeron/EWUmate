-- Table: feedbacks
-- Roles: ['authenticated']
-- Command: UPDATE
ALTER TABLE feedbacks ENABLE ROW LEVEL SECURITY;
CREATE POLICY Enable update for all users ON feedbacks
FOR UPDATE
TO authenticated
USING (true)
;
