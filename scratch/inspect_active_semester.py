import psycopg2
from psycopg2.extras import RealDictCursor

def check_sync_status():
    try:
        conn = psycopg2.connect('postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres')
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        print("--- Columns in scraper_logs ---")
        cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'scraper_logs'")
        print([c['column_name'] for c in cur.fetchall()])

        print("\n--- Latest Scraper Log ---")
        cur.execute("SELECT * FROM scraper_logs ORDER BY created_at DESC LIMIT 1")
        log = cur.fetchone()
        print(log)

        print("\n--- Latest HTTP Responses (pg_net) ---")
        cur.execute("SELECT * FROM net._http_response ORDER BY created DESC LIMIT 3")
        responses = cur.fetchall()
        for r in responses:
            print(r)

        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_sync_status()
