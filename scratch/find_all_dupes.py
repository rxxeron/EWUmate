import psycopg2

db_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def find_duplicates():
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        
        cur.execute("SELECT code FROM semesters;")
        codes = [row[0] for row in cur.fetchall()]
        
        normalized = {}
        duplicates = []
        
        for code in codes:
            clean = code.lower().replace(' ', '').replace('_', '')
            if clean in normalized:
                duplicates.append((clean, normalized[clean], code))
            else:
                normalized[clean] = code
                
        if duplicates:
            print("Found duplicate pairs in semesters table:")
            for clean, first, second in duplicates:
                print(f"\n- Pair for '{clean}': '{first}' vs '{second}'")
                
                # Check Profiles
                cur.execute(f"SELECT COUNT(*) FROM profiles WHERE admitted_semester = %s", (first,))
                p1 = cur.fetchone()[0]
                cur.execute(f"SELECT COUNT(*) FROM profiles WHERE admitted_semester = %s", (second,))
                p2 = cur.fetchone()[0]
                print(f"    - profiles: {first} ({p1}) | {second} ({p2})")

                # Check Enrollments
                cur.execute(f"SELECT COUNT(*) FROM enrollments WHERE semester_code = %s", (first,))
                e1 = cur.fetchone()[0]
                cur.execute(f"SELECT COUNT(*) FROM enrollments WHERE semester_code = %s", (second,))
                e2 = cur.fetchone()[0]
                print(f"    - enrollments: {first} ({e1}) | {second} ({e2})")

                # Check Completed Courses
                cur.execute(f"SELECT COUNT(*) FROM completed_courses WHERE semester_code = %s", (first,))
                c1 = cur.fetchone()[0]
                cur.execute(f"SELECT COUNT(*) FROM completed_courses WHERE semester_code = %s", (second,))
                c2 = cur.fetchone()[0]
                print(f"    - completed_courses: {first} ({c1}) | {second} ({c2})")
        else:
            print("No duplicates found.")
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    find_duplicates()
