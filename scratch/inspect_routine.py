import psycopg2
from psycopg2 import extras

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def main():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor(cursor_factory=extras.RealDictCursor)
        
        cur.execute("""
            SELECT routine_name, routine_definition, routine_schema, data_type
            FROM information_schema.routines
            WHERE routine_name = 'update_drive_account_used_bytes';
        """)
        routine = cur.fetchone()
        if routine:
            print("--- FUNCTION DEFINITION ---")
            print(routine['routine_definition'])
        else:
            print("Function 'update_drive_account_used_bytes' not found!")
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
