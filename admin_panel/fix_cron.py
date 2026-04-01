import psycopg2

DATABASE_URL = 'postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres'

try:
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = True
    cur = conn.cursor()
    
    # Fetch the real token from job 4
    cur.execute("SELECT command FROM cron.job WHERE jobid = 4")
    job4_cmd = cur.fetchone()[0]
    
    token_start = job4_cmd.find('Bearer ') + 7
    token_end = job4_cmd.find('"', token_start)
    real_token = job4_cmd[token_start:token_end]
    
    if real_token.startswith('eyJ'):
        new_cmd = f"""
        SELECT
          net.http_post(
              url:='https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/alert-dispatcher',
              headers:='{{"Content-Type": "application/json", "Authorization": "Bearer {real_token}"}}'::jsonb,
              body:='{{}}'::jsonb
          ) AS request_id;
        """
        cur.execute("SELECT cron.alter_job(job_id := 5, command := %s)", (new_cmd,))
        print("SUCCESS: Updated cron job 5 with the real token!")
        
        cur.execute("SELECT jobid, command FROM cron.job WHERE jobid = 5")
        print("Verified Job 5 Command:", cur.fetchone()[1][:150], "...")
    else:
        print("Could not extract real token.")

except Exception as e:
    print(f"Error: {e}")
