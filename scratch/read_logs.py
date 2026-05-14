import psycopg2

try:
    conn = psycopg2.connect('postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres')
    cur = conn.cursor()
    cur.execute("SELECT report, created_at FROM scraper_logs ORDER BY created_at DESC LIMIT 5")
    rows = cur.fetchall()
    for r in rows:
        print(f"[{r[1]}] {r[0]}")
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")
