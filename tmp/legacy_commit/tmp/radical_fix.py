import psycopg2

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def radical_fix():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        print("Dropping old table if exists...")
        cur.execute("DROP TABLE IF EXISTS public.saved_schedules CASCADE;")
        cur.execute("DROP TABLE IF EXISTS public.user_drafts CASCADE;")
        
        print("Creating simplified user_drafts table...")
        cur.execute("""
            CREATE TABLE public.user_drafts (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID NOT NULL,
                semester_code TEXT NOT NULL,
                combination_data JSONB NOT NULL,
                created_at TIMESTAMPTZ DEFAULT now() NOT NULL
            );
        """)
        
        print("Granting absolute permissions...")
        cur.execute("GRANT ALL ON TABLE public.user_drafts TO postgres, authenticator, anon, authenticated, service_role;")
        cur.execute("GRANT USAGE ON SCHEMA public TO postgres, authenticator, anon, authenticated, service_role;")
        
        print("Disabling RLS...")
        cur.execute("ALTER TABLE public.user_drafts DISABLE ROW LEVEL SECURITY;")
        
        print("Reloading PostgREST schema cache...")
        cur.execute("NOTIFY pgrst, 'reload schema';")
        
        conn.commit()
        cur.close()
        conn.close()
        print("RADICAL_FIX_SUCCESS")
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    radical_fix()
