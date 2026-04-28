import psycopg2

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# Set it to a future date to unblock the UI
cur.execute("UPDATE active_semester SET grade_submission_start = CURRENT_DATE + INTERVAL '30 days' WHERE track = 'tri_semester'")
conn.commit()

cur.execute("SELECT grade_submission_start FROM active_semester WHERE track = 'tri_semester'")
new_date = cur.fetchone()[0]

print(f"Date restored to future! New Date: {new_date}")
