import psycopg2

try:
    conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
    cursor = conn.cursor()
    
    query_triggers = """
    SELECT event_object_table, trigger_name, action_statement
    FROM information_schema.triggers
    WHERE trigger_schema = 'public' OR trigger_schema = 'storage';
    """
    
    cursor.execute(query_triggers)
    triggers = cursor.fetchall()
    
    with open("scratch/all_triggers.txt", "w") as f:
        f.write("--- All Triggers ---\n")
        for t in triggers:
            f.write(f"Table: {t[0]} | Trigger: {t[1]}\nAction: {t[2]}\n\n")
            
except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals() and conn:
        cursor.close()
        conn.close()
