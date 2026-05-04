import psycopg2

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def find_table_info(t_name):
    try:
        conn = psycopg2.connect(conn_url)
        cur = conn.cursor()
        
        print(f"--- INFO FOR {t_name} ---")
        
        # Find which schema it's in
        cur.execute(f"SELECT table_schema FROM information_schema.tables WHERE table_name = '{t_name}';")
        schemas = cur.fetchall()
        print(f"Schemas: {schemas}")
        
        for schema in [s[0] for s in schemas]:
            print(f"\nConstraints in {schema}:")
            cur.execute(f"""
                SELECT conname, pg_get_constraintdef(oid)
                FROM pg_constraint
                WHERE conrelid = '"{schema}"."{t_name}"'::regclass;
            """)
            constraints = cur.fetchall()
            for cname, cdef in constraints:
                print(f" - {cname} | {cdef}")

        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Database Error: {e}")

if __name__ == "__main__":
    find_table_info('semester_course_marks')
