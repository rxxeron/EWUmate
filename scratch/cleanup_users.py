import psycopg2

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def cleanup_unauthorized_users():
    try:
        conn = psycopg2.connect(conn_url)
        conn.autocommit = True
        cur = conn.cursor()
        
        cur.execute("DELETE FROM auth.users WHERE email NOT LIKE '%@std.ewubd.edu';")
        print(f"Cleanup complete. Deleted {cur.rowcount} unauthorized accounts.")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    cleanup_unauthorized_users()
