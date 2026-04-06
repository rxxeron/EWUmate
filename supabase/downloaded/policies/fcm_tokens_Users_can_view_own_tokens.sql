-- Table: fcm_tokens
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY Users can view own tokens ON fcm_tokens
FOR SELECT
TO public
USING ((auth.uid() = user_id))
;
