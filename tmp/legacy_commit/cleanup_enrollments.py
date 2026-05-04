import psycopg2
import json
from datetime import datetime

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def cleanup_enrollments_simplified():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        # 1. Audit based on the 'Ongoing' rule (grade IS NULL)
        print("Auditing enrollments for Completed vs Ongoing courses...")
        cur.execute("SELECT COUNT(*) FROM enrollments WHERE grade IS NOT NULL;")
        completed_count = cur.fetchone()[0]
        
        cur.execute("SELECT COUNT(*) FROM enrollments WHERE grade IS NULL;")
        ongoing_count = cur.fetchone()[0]
        
        print(f"Targeting: {completed_count} completed records for removal.")
        print(f"Preserving: {ongoing_count} ongoing records (grade IS NULL).")
        
        if completed_count == 0:
            print("No completed records found to clean up. Exiting.")
            return

        # 2. Backup before deletion (Precaution)
        print("\nBacking up historical enrollment data...")
        cur.execute("SELECT * FROM enrollments WHERE grade IS NOT NULL;")
        rows = cur.fetchall()
        
        backup_file = f"enrollments_cleanup_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(backup_file, 'w') as f:
            json.dump(rows, f, indent=4, default=str)
        print(f"Safety Backup created: {backup_file}")

        # 3. Execution
        print("\nExecuting permanent removal of completed enrollments...")
        cur.execute("DELETE FROM enrollments WHERE grade IS NOT NULL;")
        conn.commit()
        print(f"SUCCESS: {completed_count} completed records removed from your active enrollment table.")
        
    except Exception as e:
        print(f"ERROR: {e}")
        if conn: conn.rollback()
    finally:
        if cur: cur.close()
        if conn: conn.close()

if __name__ == '__main__':
    cleanup_enrollments_simplified()
