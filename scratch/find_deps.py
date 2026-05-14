import psycopg2

db_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def find_dependent_views():
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        
        tables = ['semesters', 'profiles', 'enrollments', 'active_semester']
        
        for table in tables:
            print(f"\nChecking views dependent on {table}:")
            cur.execute("""
                SELECT DISTINCT v.relname AS view_name
                FROM pg_depend d
                JOIN pg_rewrite r ON r.oid = d.objid
                JOIN pg_class v ON v.oid = r.ev_class
                JOIN pg_class t ON t.oid = d.refobjid
                WHERE t.relname = %s AND v.relkind = 'v';
            """, (table,))
            rows = cur.fetchall()
            for row in rows:
                print(f"  - {row[0]}")
                
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    find_dependent_views()
