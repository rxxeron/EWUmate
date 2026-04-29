import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def get_logic():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        # 1. Search for functions that mention 'profiles' and 'INSERT'
        cur.execute("""
            SELECT routine_name, routine_definition FROM information_schema.routines 
            WHERE routine_definition ILIKE '%INSERT%INTO%profiles%'
            AND routine_schema = 'public';
        """)
        results = cur.fetchall()
        for name, ddl in results:
            print(f"--- FUNCTION: {name} ---")
            print(ddl)
            print("-" * 20)
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    get_logic()
