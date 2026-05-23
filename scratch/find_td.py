import psycopg2
import os

db_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

try:
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()
    
    # 1. Get all public tables
    cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='public'")
    tables = [t[0] for t in cur.fetchall()]
    print("Tables found:", tables)
    
    # 2. Search for TD in each table
    for table in tables:
        try:
            # Get columns of the table
            cur.execute(f"SELECT column_name, data_type FROM information_schema.columns WHERE table_name='{table}'")
            cols = cur.fetchall()
            
            # Build query to search text/varchar columns for 'TD'
            text_cols = [c[0] for c in cols if c[1] in ('text', 'character varying', 'user-defined')]
            if not text_cols:
                continue
                
            conditions = []
            for col in text_cols:
                conditions.append(f"UPPER(\"{col}\"::text) = 'TD'")
                
            query = f"SELECT * FROM \"{table}\" WHERE " + " OR ".join(conditions) + " LIMIT 5"
            cur.execute(query)
            results = cur.fetchall()
            if results:
                print(f"\nFound TD in table `{table}`:")
                print("Columns:", [c[0] for c in cols])
                for row in results:
                    print("Row:", row)
        except Exception as e:
            # Rollback transaction on error to continue
            conn.rollback()
            # print(f"Error querying {table}: {e}")
            
except Exception as e:
    print("Database connection error:", e)
