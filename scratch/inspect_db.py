import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def inspect_db():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    # List tables in public schema
    cur.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public';
    """)
    tables = cur.fetchall()
    print("Tables in public:")
    for t in tables:
        print(f" - {t[0]}")
        
    cur.close()
    conn.close()

if __name__ == "__main__":
    inspect_db()
