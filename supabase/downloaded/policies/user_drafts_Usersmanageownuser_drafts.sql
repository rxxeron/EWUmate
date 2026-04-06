-- Table: user_drafts
-- Roles: ['public']
-- Command: ALL
ALTER TABLE user_drafts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own user_drafts" ON "user_drafts"
FOR ALL
TO public
USING (((auth.uid())::text = (user_id)::text))
WITH CHECK (((auth.uid())::text = (user_id)::text))
;
