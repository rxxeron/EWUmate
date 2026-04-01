import psycopg2
DATABASE_URL = 'postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres'
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()
cur.execute("SELECT * FROM schedule_exceptions LIMIT 3")
print("Exceptions:", cur.fetchall())
