import psycopg2
from psycopg2 import extras

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def inspect():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor(cursor_factory=extras.RealDictCursor)
        
        cur.execute("SELECT id, file_name, course_code, faculty_initial, semester, file_type FROM study_materials;")
        rows = cur.fetchall()
        print(f"Total rows in study_materials: {len(rows)}")
        for idx, row in enumerate(rows):
            print(f"Row {idx+1}:")
            print(f"  id: {row['id']}")
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
    inspect()
