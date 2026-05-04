import psycopg2

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def force_update_analytics():
    try:
        conn = psycopg2.connect(conn_url)
        conn.autocommit = True
        cur = conn.cursor()
        
        user_id = 'bd73b4d7-d922-458f-a52c-40e30e148bf4'
        semester_code = 'Spring2026'
        
        cur.execute(f"""
            UPDATE semester_analytics 
            SET taken_in_this_sem = 14.0 
            WHERE user_id = '{user_id}' AND semester_code = '{semester_code}';
        """)
        print("Analytics force updated to 14.0 credits.")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    force_update_analytics()
