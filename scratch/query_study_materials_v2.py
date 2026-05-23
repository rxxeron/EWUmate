import psycopg2
from psycopg2 import extras

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def main():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor(cursor_factory=extras.RealDictCursor)
        
        cur.execute("SELECT id, file_name, status, uploader_id, updated_at FROM study_materials;")
        rows = cur.fetchall()
        print(f"Total rows in study_materials: {len(rows)}")
        for idx, row in enumerate(rows):
            print(f"Row {idx+1}:")
            print(f"  id: {row['id']}")
            print(f"  file_name: {row['file_name']}")
            print(f"  status: {row['status']}")
            print(f"  uploader_id: {row['uploader_id']}")
            print(f"  updated_at: {row['updated_at']}")
            print("-" * 30)
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
