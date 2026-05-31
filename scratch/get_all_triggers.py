import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def check_all_triggers():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        print("=== ALL TRIGGERS ON auth.users ===")
        cur.execute("""
            SELECT 
                tgname AS trigger_name,
                proname AS function_name,
                prosrc AS function_source
            FROM pg_trigger
            JOIN pg_proc ON pg_proc.oid = pg_trigger.tgfoid
            WHERE tgrelid = 'auth.users'::regclass;
        """)
        triggers = cur.fetchall()
        if not triggers:
            print("No triggers found on auth.users.")
        for trg in triggers:
            print(f"Trigger Name: {trg[0]}")
            print(f"Function Name: {trg[1]}")
            print(f"Source:\n{trg[2]}")
            print("-" * 50)
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error checking triggers: {e}")

if __name__ == "__main__":
    check_all_triggers()
