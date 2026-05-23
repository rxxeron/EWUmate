import psycopg2
from psycopg2 import extras

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def check_and_update():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor(cursor_factory=extras.RealDictCursor)
        
        # Check semesters
        cur.execute("SELECT code, title FROM semesters WHERE code IN ('spring2022', 'summer2026', 'summer2025');")
        sems = cur.fetchall()
        print("Existing semesters:")
        for s in sems:
            print(f"  {s['code']}: {s['title']}")
            
        # Check courses
        cur.execute("SELECT code, name FROM course_metadata WHERE code IN ('CSE207', 'CSE251', 'MAT101');")
        courses = cur.fetchall()
        print("Existing courses:")
        for c in courses:
            print(f"  {c['code']}: {c['name']}")
            
        # Update Row 1: CSE251_ICE213_Course Outline_Summer 2026.pdf
        # Let's set its course_code to 'CSE251', semester to 'summer2026', file_type to 'Course Outline'
        cur.execute("""
            UPDATE study_materials 
            SET course_code = 'CSE251', semester = 'summer2026', file_type = 'Course Outline'
            WHERE file_name = 'CSE251_ICE213_Course Outline_Summer 2026.pdf';
        """)
        
        # Update Row 2: Course Outline_CSE 207_Spring 2022.docx
        # Let's set its course_code to 'CSE207', semester to 'spring2022', file_type to 'Course Outline'
        cur.execute("""
            UPDATE study_materials 
            SET course_code = 'CSE207', semester = 'spring2022', file_type = 'Course Outline'
            WHERE file_name = 'Course Outline_CSE 207_Spring 2022.docx';
        """)
        
        conn.commit()
        print("Successfully updated study_materials rows to match actual metadata!")
        
        # Print updated table to verify
        cur.execute("SELECT * FROM study_materials;")
        rows = cur.fetchall()
        print("\nUpdated study materials rows:")
        for idx, row in enumerate(rows):
            print(f"Row {idx+1}:")
            print(f"  file_name: {row['file_name']}")
            print(f"  course_code: {row['course_code']}")
            print(f"  faculty_initial: {row['faculty_initial']}")
            print(f"  semester: {row['semester']}")
            print(f"  file_type: {row['file_type']}")
            print("-" * 30)
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_and_update()
