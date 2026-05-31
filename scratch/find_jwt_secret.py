import psycopg2

try:
    conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
    cur = conn.cursor()
    cur.execute("SELECT name, setting FROM pg_settings WHERE name LIKE '%jwt%' OR name LIKE '%secret%' OR name LIKE '%postgrest%' OR name LIKE '%key%';")
    rows = cur.fetchall()
    print(f"Found {len(rows)} matching settings.")
    for row in rows:
        print(f"{row[0]} = {row[1]}")
except Exception as e:
    print(f"Error: {e}")
