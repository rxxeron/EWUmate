import psycopg2
from psycopg2 import extras

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def main():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor(cursor_factory=extras.RealDictCursor)
        
        target_account = "c9ca4f21-4a5e-4397-b713-0d4866859a9a"
        cur.execute("""
            SELECT id, file_name, file_size_bytes, parent_id, status, created_at
            FROM study_materials
            WHERE drive_account_id = %s
            LIMIT 10;
        """, (target_account,))
        rows = cur.fetchall()
        print(f"Sample of study_materials for {target_account}:")
        for r in rows:
            print(f"  ID: {r['id']} | Name: {r['file_name']} | Size: {r['file_size_bytes']} | Parent: {r['parent_id']} | Status: {r['status']} | Created: {r['created_at']}")
            
        cur.execute("""
            SELECT COUNT(*), SUM(file_size_bytes)
            FROM study_materials
            WHERE drive_account_id = %s AND parent_id IS NULL;
        """, (target_account,))
        primaries = cur.fetchone()
        print(f"\nPrimaries (parent_id IS NULL): Count: {primaries['count']}, Sum size: {primaries['sum']} bytes")
        
        cur.execute("""
            SELECT COUNT(*), SUM(file_size_bytes)
            FROM study_materials
            WHERE drive_account_id = %s AND parent_id IS NOT NULL;
        """, (target_account,))
        peers = cur.fetchone()
        print(f"Peers (parent_id IS NOT NULL): Count: {peers['count']}, Sum size: {peers['sum']} bytes")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
