import psycopg2
from psycopg2 import extras

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def main():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor(cursor_factory=extras.RealDictCursor)
        
        # Check RLS status
        print("--- RLS STATUS ---")
        cur.execute("""
            SELECT tablename, rowsecurity 
            FROM pg_tables 
            WHERE schemaname = 'public' AND tablename IN ('drive_accounts', 'study_materials');
        """)
        for r in cur.fetchall():
            print(f"Table: {r['tablename']} | RLS Enabled: {r['rowsecurity']}")
            
        # Check RLS policies
        print("\n--- RLS POLICIES ---")
        cur.execute("""
            SELECT tablename, policyname, roles, cmd, qual, with_check
            FROM pg_policies
            WHERE schemaname = 'public' AND tablename IN ('drive_accounts', 'study_materials');
        """)
        for p in cur.fetchall():
            print(f"Table: {p['tablename']} | Policy: {p['policyname']} | Roles: {p['roles']} | Cmd: {p['cmd']}")
            print(f"  Qual: {p['qual']}")
            print(f"  With Check: {p['with_check']}")
            print("-" * 50)
            
        # Check table privileges
        print("\n--- TABLE PRIVILEGES ---")
        cur.execute("""
            SELECT grantee, privilege_type
            FROM information_schema.role_table_grants
            WHERE table_schema = 'public' AND table_name = 'drive_accounts';
        """)
        for priv in cur.fetchall():
            print(f"Grantee: {priv['grantee']} | Privilege: {priv['privilege_type']}")
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
