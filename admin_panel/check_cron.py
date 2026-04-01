import psycopg2
DATABASE_URL = 'postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres'
try:
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    cur.execute("SELECT jobid, schedule, command, jobname FROM cron.job")
    jobs = cur.fetchall()
    if not jobs:
        print("No cron jobs found in cron.job table.")
    else:
        for job in jobs:
            print(f"Job ID: {job[0]}, Name: {job[3]}, Schedule: {job[1]}")
            print(f"Command:\n{job[2]}\n")
except Exception as e:
    print(f"Error: {e}")
