import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def find_user_trigger():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        print("--- TRIGGERS ON USERS ---")
        cur.execute("""
            SELECT trigger_name, event_object_schema, event_object_table, action_statement 
            FROM information_schema.triggers 
            WHERE event_object_table = 'users';
        """)
        triggers = cur.fetchall()
        for trg in triggers:
            print(f"Trigger: {trg[0]} | Schema: {trg[1]} | Table: {trg[2]}")
            print(f"Action: {trg[3]}\n")
            
        print("--- NEW USER FUNCTIONS ---")
        # Search for any function that inserts into profiles
        cur.execute("""
            SELECT routine_name, routine_definition, routine_schema
            FROM information_schema.routines 
            WHERE routine_definition ILIKE '%INSERT INTO%profiles%';
        """)
        funcs = cur.fetchall()
        for func in funcs:
            print(f"Function: {func[0]} | Schema: {func[2]}")
            print(f"Definition:\n{func[1]}\n")
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    find_user_trigger()
