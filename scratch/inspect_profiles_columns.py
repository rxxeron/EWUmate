import pg8000.dbapi

def main():
    conn = pg8000.dbapi.connect(
        host="aws-1-ap-south-1.pooler.supabase.com",
        database="postgres",
        user="postgres.jwygjihrbwxhehijldiz",
        password="EWUmaterh12",
        port=5432
    )
    cursor = conn.cursor()
    
    # Inspect table columns of 'profiles'
    cursor.execute("""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'profiles'
    """)
    cols = cursor.fetchall()
    print("--- SCHEMA of profiles table ---")
    for col in cols:
        print(f"Column: {col[0]:<25} | Type: {col[1]}")
        
    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()
