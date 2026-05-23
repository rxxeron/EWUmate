import psycopg2
from psycopg2 import extras

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def main():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor(cursor_factory=extras.RealDictCursor)
        
        # Query triggers and their functions on study_materials using tgname
        cur.execute("""
            SELECT 
                t.tgname AS trigger_name,
                p.prosrc AS function_definition,
                p.proname AS function_name
            FROM pg_trigger t
            JOIN pg_class c ON t.tgrelid = c.oid
            JOIN pg_proc p ON t.tgfoid = p.oid
            WHERE c.relname = 'study_materials';
        """)
        triggers = cur.fetchall()
        print("--- TRIGGERS ON study_materials AND THEIR DEFINITIONS ---")
        for t in triggers:
            print(f"Trigger Name: {t['trigger_name']} | Function: {t['function_name']}")
            print("-" * 50)
            print(t['function_definition'])
            print("=" * 50)
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
