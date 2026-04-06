-- Table: fcm_tokens
-- Roles: ['public']
-- Command: DELETE
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can delete own tokens" ON "fcm_tokens"
FOR DELETE
TO public
USING ((auth.uid() = user_id))
;
