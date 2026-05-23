import psycopg2
from psycopg2 import extras

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def main():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor(cursor_factory=extras.RealDictCursor)
        
        cur.execute("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_name = 'drive_accounts';
        """)
        cols = cur.fetchall()
        print("=== Columns of drive_accounts ===")
        for col in cols:
            print(f"{col['column_name']}: {col['data_type']} (nullable: {col['is_nullable']})")
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
