import psycopg2

try:
    conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
    cursor = conn.cursor()
    
    query = """
    SELECT
        t.tgname AS trigger_name,
        c.relname AS table_name,
        p.proname AS function_name
    FROM
        pg_trigger t
    JOIN
        pg_class c ON t.tgrelid = c.oid
    JOIN
        pg_proc p ON t.tgfoid = p.oid
    WHERE
        NOT t.tgisinternal
    """
    
    cursor.execute(query)
    triggers = cursor.fetchall()
    
    with open("scratch/pg_trigger_raw.txt", "w") as f:
        for t in triggers:
            f.write(f"Table: {t[1]} | Trigger: {t[0]} | Function: {t[2]}\n")
            
except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals() and conn:
        cursor.close()
        conn.close()
