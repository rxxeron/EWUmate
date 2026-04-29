import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def get_auth_logic():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        # Search every schema for functions that touch 'profiles'
        cur.execute("""
            SELECT routine_name, routine_definition, routine_schema
            FROM information_schema.routines 
            WHERE routine_definition ILIKE '%profiles%';
        """)
        results = cur.fetchall()
        for name, ddl, schema in results:
            if 'INSERT' in ddl.upper() and 'PROFILES' in ddl.upper():
                print(f"--- FUNCTION: {schema}.{name} ---")
                print(ddl)
                print("-" * 20)
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    get_auth_logic()
