import psycopg2

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def check():
    try:
        conn = psycopg2.connect(conn_url)
        cur = conn.cursor()
        
        cur.execute("SELECT code, name FROM course_metadata WHERE code ILIKE '%CSE251%' OR code ILIKE '%CSE207%' OR code ILIKE '%CSE 207%' OR code ILIKE '%CSE 251%';")
        rows = cur.fetchall()
        print("MATCHING COURSES:")
        for row in rows:
            print(f" - code: {row[0]} | name: {row[1]}")
            
        cur.close()
        conn.close()
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    check()
