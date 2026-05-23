import psycopg2
from psycopg2 import extras

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def main():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor(cursor_factory=extras.RealDictCursor)
        
        # Query trigger functions
        print("--- TRIGGER FUNCTIONS ---")
        cur.execute("""
            SELECT routine_name, routine_definition
            FROM information_schema.routines
            WHERE routine_schema = 'public' AND routine_type = 'FUNCTION'
            AND routine_name LIKE '%trigger%';
        """)
        funcs = cur.fetchall()
        for f in funcs:
            print(f"Function Name: {f['routine_name']}")
            print("-" * 50)
            print(f['routine_definition'])
            print("=" * 50)
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
