import psycopg2

db_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def get_view_def():
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        
        cur.execute("SELECT view_definition FROM information_schema.views WHERE table_name = 'v_semester_progress';")
        row = cur.fetchone()
        if row:
            print("View Definition for v_semester_progress:")
            print(row[0])
        else:
            print("View not found.")
            
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    get_view_def()
