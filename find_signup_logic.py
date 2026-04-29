import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def find_trig():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        # Look for triggers on auth.users (table_schema='auth', table_name='users')
        cur.execute("""
            SELECT trigger_name, action_statement, action_timing, event_manipulation
            FROM information_schema.triggers 
            WHERE event_object_schema = 'auth' AND event_object_table = 'users';
        """)
        results = cur.fetchall()
        for trg in results:
            print(f"--- TRIGGER ON AUTH.USERS: {trg[0]} ---")
            print(f"Timing: {trg[2]} {trg[3]}")
            print(f"Action: {trg[1]}\n")
            
            # If it calls a function, let's find that function
            if 'EXECUTE FUNCTION' in trg[1].upper() or 'EXECUTE PROCEDURE' in trg[1].upper():
                func_name = trg[1].split(' ')[-1].replace('()', '').replace(';', '').strip()
                print(f"Looking for function: {func_name}")
                
                cur.execute(f"""
                    SELECT routine_definition, routine_schema FROM information_schema.routines 
                    WHERE (routine_schema || '.' || routine_name) ILIKE '%{func_name}%'
                    OR routine_name ILIKE '%{func_name}%';
                """)
                func_data = cur.fetchall()
                for ddl, schema in func_data:
                    print(f"--- FUNCTION DEFINITION ({schema}.{func_name}) ---")
                    print(ddl)
                    print("-" * 20)
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    find_trig()
