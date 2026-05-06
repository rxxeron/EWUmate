import psycopg2

try:
    conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
    cursor = conn.cursor()
    
    query_triggers = """
    SELECT trigger_schema, event_object_table, trigger_name, action_statement
    FROM information_schema.triggers;
    """
    
    cursor.execute(query_triggers)
    triggers = cursor.fetchall()
    
    with open("scratch/all_schemas_triggers.txt", "w") as f:
        f.write("--- All Schemas Triggers ---\n")
        for t in triggers:
            f.write(f"Schema: {t[0]} | Table: {t[1]} | Trigger: {t[2]}\nAction: {t[3]}\n\n")
            
except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals() and conn:
        cursor.close()
        conn.close()
