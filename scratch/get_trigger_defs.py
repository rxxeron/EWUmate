import psycopg2

try:
    conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
    cursor = conn.cursor()
    
    query = """
    SELECT pg_get_triggerdef(oid) 
    FROM pg_trigger 
    WHERE tgname IN ('trg_master_academic_sync', 'trg_master_enrollment_sync');
    """
    
    cursor.execute(query)
    triggers = cursor.fetchall()
    
    with open("scratch/trigger_defs.txt", "w") as f:
        for t in triggers:
            f.write(t[0] + "\n\n")
            
except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals() and conn:
        cursor.close()
        conn.close()
