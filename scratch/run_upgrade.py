import psycopg2

try:
    conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
    conn.autocommit = True
    cursor = conn.cursor()
    
    with open("scratch/upgrade_triggers.sql", "r") as f:
        sql = f.read()
        
    print("Executing SQL script...")
    cursor.execute(sql)
    print("Execution complete!")
            
except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals() and conn:
        cursor.close()
        conn.close()
