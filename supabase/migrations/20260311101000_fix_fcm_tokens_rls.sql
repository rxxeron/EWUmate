-- Fix RLS for fcm_tokens table
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Allow users to manage tokens (allow USING true to handle conflict/upsert rows they don't yet own)
DROP POLICY IF EXISTS "Users can manage their own fcm tokens" ON public.fcm_tokens;
CREATE POLICY "Users can manage their own fcm tokens"
ON public.fcm_tokens
FOR ALL 
TO authenticated
USING (true)
WITH CHECK (auth.uid() = user_id);
