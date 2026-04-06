-- Table: fcm_tokens
-- Roles: ['public']
-- Command: UPDATE
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can update tokens on their device" ON "fcm_tokens"
FOR UPDATE
TO public
USING (true)
WITH CHECK ((auth.uid() = user_id))
;
