import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def inspect_columns():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    # List all columns containing 'version' or 'app' or in tables profiles / fcm_tokens
    cur.execute("""
        SELECT table_name, column_name, data_type 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND (
            column_name LIKE '%version%' 
            OR column_name LIKE '%app%'
            OR table_name IN ('profiles', 'fcm_tokens', 'user_semester_states')
          );
    """)
    columns = cur.fetchall()
    print("Columns found:")
    for c in columns:
        print(f" - {c[0]}.{c[1]} ({c[2]})")
        
    cur.close()
    conn.close()

if __name__ == "__main__":
    inspect_columns()
