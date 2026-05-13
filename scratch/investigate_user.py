import psycopg2

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def get_user_data(student_id):
    try:
        conn = psycopg2.connect(conn_url)
        cur = conn.cursor()
        
        cur.execute(f"SELECT id, full_name FROM profiles WHERE student_id = '{student_id}';")
        user = cur.fetchone()
        if not user:
            print(f"User {student_id} not found.")
            return
        
        uid = user[0]
        print(f"User Found: {user[1]} ({uid})")
        
        print("\n--- Upcoming Enrollments ---")
        cur.execute(f"SELECT course_code, section, semester_code, status FROM enrollments WHERE user_id = '{uid}' AND status = 'upcoming';")
        enrollments = cur.fetchall()
        for code, section, sem, status in enrollments:
            print(f"{code} Sec {section} | Semester: {sem} | Status: {status}")

        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Database Error: {e}")

if __name__ == "__main__":
    get_user_data('2025-2-50-009')
