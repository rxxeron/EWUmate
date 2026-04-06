-- Table: fcm_tokens
-- Roles: ['public']
-- Command: INSERT
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert their tokens" ON "fcm_tokens"
FOR INSERT
TO public
WITH CHECK ((auth.uid() = user_id))
;
