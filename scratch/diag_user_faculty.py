import psycopg2

try:
    conn = psycopg2.connect('postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres')
    cur = conn.cursor()
    
    # 1. Get User ID
    email = 'rhrakibulhasan279@gmail.com'
    cur.execute("SELECT id FROM profiles WHERE email = %s", (email,))
    user_res = cur.fetchone()
    if not user_res:
        print(f"User {email} not found.")
        cur.close()
        conn.close()
        exit()
    user_id = user_res[0]
    print(f"User ID: {user_id}")

    # 2. Get Enrollments for Summer 2026 (assuming semester code 'summer2026')
    # Let's check the enrollments table structure
    cur.execute("SELECT course_code, section_number, semester_code FROM enrollments WHERE profile_id = %s AND semester_code = 'summer2026'", (user_id,))
    enrolls = cur.fetchall()
    print(f"Enrollments: {enrolls}")

    # 3. Check the courses_summer2026 table for these enrollments
    for code, sec, sem in enrolls:
        cur.execute("SELECT faculty_initials, faculty_full_name FROM courses_summer2026 WHERE course_code = %s AND section_number = %s", (code, str(sec)))
        course_info = cur.fetchone()
        print(f"Course {code} Sec {sec}: DB State = {course_info}")

    cur.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")
