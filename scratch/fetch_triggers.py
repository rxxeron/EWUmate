import psycopg2

try:
    conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
    cursor = conn.cursor()
    
    # 1. Check Triggers that might call webhooks
    query_triggers = """
    SELECT event_object_table, trigger_name, action_statement
    FROM information_schema.triggers
    WHERE action_statement LIKE '%http_request%' OR action_statement LIKE '%net.http_post%';
    """
    
    cursor.execute(query_triggers)
    triggers = cursor.fetchall()
    
    with open("scratch/db_triggers.txt", "w") as f:
        f.write("--- Webhook Triggers ---\n")
        for t in triggers:
            f.write(f"Table: {t[0]} | Trigger: {t[1]}\nAction: {t[2]}\n\n")
            
    # 2. Check pg_cron jobs
    query_cron = """
    SELECT jobname, schedule, command
    FROM cron.job;
    """
    
    cursor.execute(query_cron)
    crons = cursor.fetchall()
    
    with open("scratch/db_crons.txt", "w") as f:
        f.write("--- Cron Jobs ---\n")
        for c in crons:
            f.write(f"Name: {c[0]} | Schedule: {c[1]}\nCommand: {c[2]}\n\n")
            
except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals() and conn:
        cursor.close()
        conn.close()
