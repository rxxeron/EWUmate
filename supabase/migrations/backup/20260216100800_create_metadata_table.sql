CREATE TABLE IF NOT EXISTS metadata (
    id TEXT PRIMARY KEY,
    data JSONB NOT NULL DEFAULT '{}'::jsonb,  -- Stores the full Firestore document content
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure columns exist (in case table was created with different schema)
ALTER TABLE metadata ADD COLUMN IF NOT EXISTS data JSONB;
ALTER TABLE metadata ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Enable RLS
ALTER TABLE metadata ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public read access" ON metadata;
DROP POLICY IF EXISTS "Allow service role full access" ON metadata;

-- Allow public read access (assuming metadata like course lists is public)
CREATE POLICY "Allow public read access" ON metadata FOR SELECT USING (true);

-- Allow service role full access
CREATE POLICY "Allow service role full access" ON metadata 
FOR ALL USING (auth.role() = 'service_role');
