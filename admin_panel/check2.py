import psycopg2
DATABASE_URL = 'postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres'
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()
cur.execute("SELECT schedule_data FROM courses_spring2026 LIMIT 1")
print(cur.fetchall())
cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'schedule_exceptions'")
print("Exceptions Schema:", cur.fetchall())
cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'tasks'")
print("Tasks Schema:", cur.fetchall())
