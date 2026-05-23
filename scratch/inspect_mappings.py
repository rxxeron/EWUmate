import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def main():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    cur.execute("""
        SELECT code, same_course 
        FROM public.course_metadata 
        WHERE same_course IS NOT NULL 
        ORDER BY code;
    """)
    rows = cur.fetchall()
    
    print("--- Mapped Equivalents in Supabase ---")
    for code, same_course in rows:
        print(f"Course: {code} <===> Same Course (Equivalent): {same_course}")
        
    cur.close()
    conn.close()

if __name__ == '__main__':
    main()
