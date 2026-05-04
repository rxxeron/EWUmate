import psycopg2

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def enable_rls_secure():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        print("Re-enabling RLS on user_drafts...")
        cur.execute("ALTER TABLE public.user_drafts ENABLE ROW LEVEL SECURITY;")
        
        print("Creating secure Row Level Security policies...")
        
        # Select
        cur.execute("DROP POLICY IF EXISTS \"Users can view their own drafts\" ON public.user_drafts;")
        cur.execute("""
            CREATE POLICY \"Users can view their own drafts\" 
            ON public.user_drafts FOR SELECT 
            USING (auth.uid() = user_id);
        """)

        # Insert
        cur.execute("DROP POLICY IF EXISTS \"Users can insert their own drafts\" ON public.user_drafts;")
        cur.execute("""
            CREATE POLICY \"Users can insert their own drafts\" 
            ON public.user_drafts FOR INSERT 
            WITH CHECK (auth.uid() = user_id);
        """)

        # Delete (Allow users to remove drafts)
        cur.execute("DROP POLICY IF EXISTS \"Users can delete their own drafts\" ON public.user_drafts;")
        cur.execute("""
            CREATE POLICY \"Users can delete their own drafts\" 
            ON public.user_drafts FOR DELETE 
            USING (auth.uid() = user_id);
        """)
        
        print("Reloading schema cache...")
        cur.execute("NOTIFY pgrst, 'reload schema';")
        
        conn.commit()
        cur.close()
        conn.close()
        print("RLS_SECURE_SUCCESS")
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    enable_rls_secure()
