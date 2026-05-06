import psycopg2

try:
    conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
    cursor = conn.cursor()
    
    query = """
    SELECT proname, prosrc
    FROM pg_proc
    WHERE prosrc LIKE '%net.http_post%';
    """
    
    cursor.execute(query)
    funcs = cursor.fetchall()
    
    with open("scratch/http_funcs.txt", "w") as f:
        for p in funcs:
            f.write(f"--- Function: {p[0]} ---\n")
            f.write(f"{p[1]}\n\n")
            
except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals() and conn:
        cursor.close()
        conn.close()
