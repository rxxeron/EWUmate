-- Table: feedbacks
-- Roles: ['authenticated']
-- Command: SELECT
ALTER TABLE feedbacks ENABLE ROW LEVEL SECURITY;
CREATE POLICY Enable read access for all users ON feedbacks
FOR SELECT
TO authenticated
USING (true)
;
