-- Table: scholarship_policies
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE scholarship_policies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view scholarship policies" ON "scholarship_policies"
FOR SELECT
TO public
USING (true)
;
