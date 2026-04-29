import psycopg2
import json

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def migrate():
    conn = None
    cur = None
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        # 1. Fetch active semester code to distinguish current vs next
        cur.execute("SELECT * FROM active_semester LIMIT 1")
        active_res = cur.fetchone()
        active_semester = active_res[1] if active_res else 'Spring2026'
        print(f"Active Semester determined from DB: {active_semester}")
        
        # 2. Fetch all profiles
        cur.execute("SELECT id FROM profiles")
        users = [u[0] for u in cur.fetchall()]
        print(f"Found {len(users)} profiles to migrate.")
        
        for user_id in users:
            # Get all enrollments for this user with status 'enrolled'
            cur.execute("""
                SELECT id, semester_code 
                FROM enrollments 
                WHERE user_id = %s AND status = 'enrolled'
            """, (user_id,))
            enrollments = cur.fetchall()
            
            current_uuids = []
            next_uuids = []
            
            for eid, sem in enrollments:
                if sem == active_semester:
                    current_uuids.append(eid)
                else:
                    next_uuids.append(eid)
            
            # Update profile
            cur.execute("""
                UPDATE profiles 
                SET enrolled_sections = %s, enrolled_sections_next = %s 
                WHERE id = %s
            """, (current_uuids, next_uuids, user_id))
            
        conn.commit()
        print(f"SUCCESS: {len(users)} profiles migrated to UUID section lists.")
        
    except Exception as e:
        print(f"ERROR: {e}")
        if conn: conn.rollback()
    finally:
        if cur: cur.close()
        if conn: conn.close()

if __name__ == '__main__':
    migrate()
