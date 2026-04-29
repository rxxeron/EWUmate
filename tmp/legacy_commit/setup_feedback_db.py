import psycopg2
conn = psycopg2.connect('postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres')
cur = conn.cursor()
cur.execute('''
CREATE TABLE IF NOT EXISTS feedbacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved', 'ignored')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE feedbacks ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON feedbacks;
    CREATE POLICY "Enable insert for authenticated users only" ON feedbacks FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
    
    DROP POLICY IF EXISTS "Enable read access for all users" ON feedbacks;
    CREATE POLICY "Enable read access for all users" ON feedbacks FOR SELECT TO authenticated USING (true);
    
    DROP POLICY IF EXISTS "Enable update for all users" ON feedbacks;
    CREATE POLICY "Enable update for all users" ON feedbacks FOR UPDATE TO authenticated USING (true);
END
$$;
''')
conn.commit()
print('Feedbacks table created successfully!')
