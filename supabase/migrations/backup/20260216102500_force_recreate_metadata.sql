-- Force recreate metadata table because of schema mismatch
DROP TABLE IF EXISTS metadata CASCADE;

CREATE TABLE metadata (
    id TEXT PRIMARY KEY,
    data JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE metadata ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Allow public read access" ON metadata FOR SELECT USING (true);
CREATE POLICY "Allow service role full access" ON metadata FOR ALL USING (auth.role() = 'service_role');
