import psycopg2

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def inspect():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        user_id = '374a09cd-c366-4eea-89cc-dbda99154c3e'
        
        cur.execute("SELECT enrolled_sections, enrolled_sections_next FROM profiles WHERE id = %s", (user_id,))
        profile = cur.fetchone()
        print(f"Profile enrolled_sections: {profile[0]}")
        print(f"Profile enrolled_sections_next: {profile[1]}")
        
        if profile[0] and len(profile[0]) > 0:
            first_id = profile[0][0]
            print(f"\nInspecting Enrollment ID: {first_id}")
            cur.execute("SELECT * FROM enrollments WHERE id = %s", (first_id,))
            enrollment = cur.fetchone()
            print(f"Enrollment Record: {enrollment}")
            
            # Get column names
            cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'enrollments'")
            cols = [c[0] for c in cur.fetchall()]
            print(f"Enrollment Columns: {cols}")
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == '__main__':
    inspect()
