import psycopg2

try:
    conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
    cursor = conn.cursor()
    
    query = """
    SELECT
      query,
      calls,
      total_exec_time,
      mean_exec_time,
      rows
    FROM pg_stat_statements
    ORDER BY total_exec_time DESC
    LIMIT 10;
    """
    
    cursor.execute(query)
    records = cursor.fetchall()
    
    with open("scratch/query_stats.txt", "w") as f:
        for row in records:
            f.write("-" * 50 + "\n")
            f.write(f"Total Time: {row[2]:.2f}ms | Calls: {row[1]} | Mean Time: {row[3]:.2f}ms | Rows: {row[4]}\n")
            f.write(f"Query: {row[0][:500]}\n")

        
except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals() and conn:
        cursor.close()
        conn.close()
