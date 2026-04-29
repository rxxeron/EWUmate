import psycopg2

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def sync_master_semesters():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        # 1. Identify missing semesters
        print("Finding semesters referenced in profiles but missing from master table...")
        cur.execute("""
            SELECT DISTINCT admitted_semester 
            FROM profiles 
            WHERE admitted_semester IS NOT NULL 
              AND admitted_semester NOT IN (SELECT code FROM semesters);
        """)
        missing = [r[0] for r in cur.fetchall()]
        
        if not missing:
            print("No missing semesters found. Your master table is sync'd.")
            return

        print(f"Found {len(missing)} missing semesters: {missing}")

        # 2. Bulk Insert with generated titles
        # Columns: code, title, is_active, created_at
        for code in missing:
            title = code.replace('_', ' ').title()
            print(f" - Inserting: {code} ({title})")
            cur.execute("""
                INSERT INTO semesters (code, title, is_active, created_at)
                VALUES (%s, %s, false, NOW())
                ON CONFLICT (code) DO NOTHING;
            """, (code, title))
            
        conn.commit()
        print("SUCCESS: Master 'semesters' table synchronized.")
        
    except Exception as e:
        print(f"ERROR: {e}")
        if conn: conn.rollback()
    finally:
        if cur: cur.close()
        if conn: conn.close()

if __name__ == '__main__':
    sync_master_semesters()
