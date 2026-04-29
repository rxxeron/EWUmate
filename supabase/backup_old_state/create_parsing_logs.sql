CREATE TABLE IF NOT EXISTS public.parsing_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_type VARCHAR NOT NULL,
    semester VARCHAR,
    file_name VARCHAR NOT NULL,
    status VARCHAR NOT NULL,
    metrics JSONB DEFAULT '{}'::jsonb,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Turn on RLS
ALTER TABLE public.parsing_logs ENABLE ROW LEVEL SECURITY;

-- Allow anon and authenticated to read for the dashboard (if you want)
-- Assuming admin has role or we just allow reads for now
CREATE POLICY "Allow authenticated read parsing_logs" 
ON public.parsing_logs FOR SELECT 
TO authenticated, anon
USING (true);

-- Allow service role to insert
CREATE POLICY "Allow service role insert parsing_logs" 
ON public.parsing_logs FOR INSERT 
TO service_role
WITH CHECK (true);
