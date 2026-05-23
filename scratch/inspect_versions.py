import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def fetch_version_counts():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    cur.execute("""
        SELECT app_version, COUNT(*) 
        FROM public.profiles 
        GROUP BY app_version 
        ORDER BY COUNT(*) DESC;
    """)
    rows = cur.fetchall()
    print("--- App Version counts ---")
    for row in rows:
        print(f"Version: {row[0]}, Count: {row[1]}")
        
    cur.close()
    conn.close()

if __name__ == "__main__":
    fetch_version_counts()
