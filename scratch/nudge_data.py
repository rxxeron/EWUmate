import psycopg2

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def nudge_data():
    try:
        conn = psycopg2.connect(conn_url)
        conn.autocommit = True
        cur = conn.cursor()
        
        user_id = 'bd73b4d7-d922-458f-a52c-40e30e148bf4'
        cur.execute(f"UPDATE semester_course_marks SET updated_at = now() WHERE user_id = '{user_id}';")
        print("Data nudged. Trigger should have fired.")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    nudge_data()
