import psycopg2

def fetch_rpc_sql():
    try:
        conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
        cursor = conn.cursor()
        
        cursor.execute("SELECT prosrc FROM pg_proc WHERE proname = 'create_calendar_table'")
        row = cursor.fetchone()
        
        if row:
            print("SQL for create_calendar_table:")
            print("-" * 40)
            print(row[0])
            print("-" * 40)
        else:
            print("Function 'create_calendar_table' not found.")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals() and conn:
            cursor.close()
            conn.close()

if __name__ == "__main__":
    fetch_rpc_sql()
