import psycopg2

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def list_tables():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")
        tables = [row[0] for row in cur.fetchall()]
        print(f"Public Tables: {tables}")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if cur: cur.close()
        if conn: conn.close()

if __name__ == '__main__':
    list_tables()
