-- Robust Fix for RLS on fcm_tokens table
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Drop previous attempt if it exists
DROP POLICY IF EXISTS "Users can manage their own fcm tokens" ON public.fcm_tokens;

-- Allow authenticated users to manage tokens.
-- USING (true) is required for upsert to find conflicting rows owned by other users.
-- WITH CHECK (auth.uid() = user_id) ensures they can only link a token to themselves.
CREATE POLICY "Users can manage their own fcm tokens"
ON public.fcm_tokens
FOR ALL 
TO authenticated
USING (true)
WITH CHECK (auth.uid() = user_id);
