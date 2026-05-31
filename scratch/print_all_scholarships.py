import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def check_all():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        cur.execute("SELECT id, department_code, effective_from_semester, effective_until_semester, min_yearly_credits, degree_credits_required FROM scholarship_policies;")
        rows = cur.fetchall()
        print("=== ALL SCHOLARSHIP POLICIES ===")
        for r in rows:
            print(r)
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_all()
