import psycopg2
from psycopg2 import extras

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def inspect():
    try:
        conn = psycopg2.connect(conn_url)
        cur = conn.cursor(cursor_factory=extras.RealDictCursor)
        
        # Get columns of faculty_master
        cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'faculty_master' AND table_schema = 'public';")
        print("--- faculty_master Columns ---")
        for r in cur.fetchall():
            print(f"  {r['column_name']}: {r['data_type']}")
            
        # Get columns of faculty_office_hours
        cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'faculty_office_hours' AND table_schema = 'public';")
        print("\n--- faculty_office_hours Columns ---")
        for r in cur.fetchall():
            print(f"  {r['column_name']}: {r['data_type']}")
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    inspect()
