import psycopg2

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def main():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        cur.execute("SELECT code, credit_val FROM course_metadata WHERE code IN ('PHRM7704', 'PHRM404')")
        rows = cur.fetchall()
        print("Final Verification:")
        for row in rows:
            print(f" - {row[0]}: {row[1]} credits")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()
