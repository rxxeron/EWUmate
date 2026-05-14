import psycopg2

db_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def check_all_tables():
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        
        cur.execute("""
            SELECT table_name, column_name 
            FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND (column_name ILIKE '%semester%' OR column_name ILIKE '%sem%');
        """)
        cols = cur.fetchall()
        
        codes = ['Summer2026', 'summer_2026']
        
        for table, col in cols:
            for code in codes:
                try:
                    cur.execute(f"SELECT COUNT(*) FROM {table} WHERE {col}::text = %s;", (code,))
                    count = cur.fetchone()[0]
                    if count > 0:
                        print(f"Match: {table}.{col} contains '{code}' ({count} rows)")
                except:
                    continue
                    
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_all_tables()
