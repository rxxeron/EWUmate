import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def print_functions():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        for func_name in ['handle_new_user', 'validate_email_domain']:
            print(f"=== FUNCTION: {func_name} ===")
            cur.execute(f"""
                SELECT routine_definition, routine_schema FROM information_schema.routines 
                WHERE routine_name = '{func_name}';
            """)
            funcs = cur.fetchall()
            if not funcs:
                print(f"Function {func_name} not found.")
            for ddl, schema in funcs:
                print(f"Schema: {schema}")
                print(ddl)
                print("-" * 40)
                
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    print_functions()
