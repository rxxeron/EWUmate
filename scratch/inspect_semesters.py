import psycopg2
from psycopg2 import extras

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def inspect():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor(cursor_factory=extras.RealDictCursor)
        
        cur.execute("SELECT code, title FROM semesters ORDER BY code DESC;")
        rows = cur.fetchall()
        print(f"Total rows in semesters: {len(rows)}")
        for idx, row in enumerate(rows):
            print(f"  {row['code']}: {row['title']}")
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    inspect()
