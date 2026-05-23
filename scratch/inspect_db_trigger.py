import psycopg2
from psycopg2 import extras

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def main():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor(cursor_factory=extras.RealDictCursor)
        
        # Check active triggers
        print("--- TRIGGERS ON study_materials ---")
        cur.execute("""
            SELECT trigger_name, event_manipulation, action_statement, action_timing
            FROM information_schema.triggers
            WHERE event_object_table = 'study_materials';
        """)
        triggers = cur.fetchall()
        for t in triggers:
            print(f"Trigger: {t['trigger_name']} | Event: {t['event_manipulation']} | Timing: {t['action_timing']}")
        
        # Check files count
        print("\n--- FILE SUMS GROUPED BY drive_account_id ---")
        cur.execute("""
            SELECT drive_account_id, COUNT(*) as count, SUM(file_size_bytes) as total_size
            FROM study_materials
            GROUP BY drive_account_id;
        """)
        sums = cur.fetchall()
        for s in sums:
            print(f"Drive Account ID: {s['drive_account_id']} | Count: {s['count']} | Total Size: {s['total_size']} bytes")
            
        # Check if there are any study_materials without drive_account_id
        cur.execute("SELECT COUNT(*) FROM study_materials WHERE drive_account_id IS NULL;")
        null_count = cur.fetchone()['count']
        print(f"\nFiles with NULL drive_account_id: {null_count}")

        # Check drive_accounts table again
        print("\n--- DRIVE ACCOUNTS ---")
        cur.execute("SELECT id, email, used_bytes FROM drive_accounts;")
        accounts = cur.fetchall()
        for a in accounts:
            print(f"Account: {a['email']} ({a['id']}) | used_bytes in DB: {a['used_bytes']}")
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
