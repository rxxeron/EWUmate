import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def inspect():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    codes = ['CSE103', 'ICE103', 'ICE204', 'CSE106']
    placeholders = ", ".join(["%s"] * len(codes))
    
    cur.execute(f"""
        SELECT code, name, equivalent_code 
        FROM course_metadata 
        WHERE code IN ({placeholders});
    """, codes)
    rows = cur.fetchall()
    
    print("--- Specific Course Metadata ---")
    for code, name, equiv in rows:
        print(f"Code: {code} | Name: {name} | Equivalent Code: {equiv}")
        
    print("\n--- Checking if equivalent_code is generally populated ---")
    cur.execute("""
        SELECT code, name, equivalent_code 
        FROM course_metadata 
        WHERE equivalent_code IS NOT NULL 
        LIMIT 10;
    """)
    non_null_rows = cur.fetchall()
    for code, name, equiv in non_null_rows:
        print(f"Code: {code} | Name: {name} | Equivalent Code: {equiv}")
        
    cur.close()
    conn.close()

if __name__ == "__main__":
    inspect()
