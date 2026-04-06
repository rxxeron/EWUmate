-- Table: scholarship_policies
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE scholarship_policies ENABLE ROW LEVEL SECURITY;
CREATE POLICY Public Read Policies ON scholarship_policies
FOR SELECT
TO public
USING (true)
;
