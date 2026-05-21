import psycopg2
import json

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def inspect():
    try:
        conn = psycopg2.connect(conn_url)
        cur = conn.cursor()
        
        # Get column names
        cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'study_materials';")
        cols = cur.fetchall()
        print("COLUMNS:")
        for col in cols:
            print(f" - {col[0]}: {col[1]}")
            
        # Get row data
        cur.execute("SELECT id, file_name, course_code, faculty_initial, semester, file_type FROM study_materials;")
        rows = cur.fetchall()
        print("\nROWS:")
        for row in rows:
            print(f" - id: {row[0]} | file_name: {row[1]} | course_code: {row[2]} | faculty_initial: {row[3]} | semester: {row[4]} | file_type: {row[5]}")
            
        cur.close()
        conn.close()
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    inspect()
