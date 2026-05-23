import psycopg2

conn_str = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

try:
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()
    
    print("Checking details of constraints matching 'study_materials_uploader_id_fkey':")
    cur.execute("""
        SELECT 
            conname as constraint_name,
            conrelid::regclass as table_name,
            confrelid::regclass as foreign_table_name,
            pg_get_constraintdef(c.oid) as constraint_definition
        FROM pg_constraint c
        WHERE conname LIKE '%uploader_id%';
    """)
    for row in cur.fetchall():
        print(row)
        
    cur.close()
    conn.close()
except Exception as e:
    print("Error:", e)
