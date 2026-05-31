import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def check_columns():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        print("=== SCHOLARSHIP_POLICIES COLUMNS ===")
        cur.execute("""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'scholarship_policies' AND table_schema = 'public';
        """)
        cols = cur.fetchall()
        for c in cols:
            print(f"Col: {c[0]} | Type: {c[1]}")
            
        print("\n=== SAMPLE ROWS ===")
        cur.execute("SELECT * FROM scholarship_policies LIMIT 3;")
        rows = cur.fetchall()
        for r in rows:
            print(r)
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_columns()
