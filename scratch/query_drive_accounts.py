import psycopg2
from psycopg2 import extras

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def main():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor(cursor_factory=extras.RealDictCursor)
        
        cur.execute("SELECT id, email, total_capacity_bytes, used_bytes, is_active, created_at, folder_id FROM drive_accounts;")
        rows = cur.fetchall()
        print(f"Total rows in drive_accounts: {len(rows)}")
        for idx, row in enumerate(rows):
            print(f"Row {idx+1}:")
            print(f"  id: {row['id']}")
            print(f"  email: {row['email']}")
            print(f"  total_capacity_bytes: {row['total_capacity_bytes']}")
            print(f"  used_bytes: {row['used_bytes']}")
            print(f"  is_active: {row['is_active']}")
            print(f"  folder_id: {row['folder_id']}")
            print(f"  created_at: {row['created_at']}")
            print("-" * 30)
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
