import psycopg2

conn_str = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

try:
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()
    
    print("Granting all privileges on study_materials to service_role...")
    cur.execute("GRANT ALL PRIVILEGES ON study_materials TO service_role;")
    conn.commit()
    print("Privileges successfully granted on study_materials to service_role!")
    
    print("Granting all sequence privileges in public schema to service_role...")
    cur.execute("GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO service_role;")
    conn.commit()
    print("Sequence privileges successfully granted to service_role!")
    
    cur.close()
    conn.close()
except Exception as e:
    print("Error:", e)
