import psycopg2

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def final_fix():
    try:
        conn = psycopg2.connect(conn_url)
        conn.autocommit = True
        cur = conn.cursor()
        
        print("--- EXECUTING FINAL DATABASE REPAIR ---")
        
        # 1. Fix semester_analytics
        print("Fixing semester_analytics...")
        cur.execute("ALTER TABLE public.semester_analytics DROP CONSTRAINT IF EXISTS semester_analytics_user_id_fkey;")
        cur.execute("ALTER TABLE public.semester_analytics ADD CONSTRAINT semester_analytics_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;")
        print("SUCCESS")

        # 2. Fix semester_course_marks (Just to be 100% sure)
        print("Fixing semester_course_marks...")
        cur.execute("ALTER TABLE public.semester_course_marks DROP CONSTRAINT IF EXISTS semester_course_marks_user_id_fkey;")
        cur.execute("ALTER TABLE public.semester_course_marks ADD CONSTRAINT semester_course_marks_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;")
        print("SUCCESS")

        # 3. Check for any other tables that point to auth.users without CASCADE
        cur.execute("""
            SELECT
                ns.nspname AS schema_name,
                cl.relname AS table_name,
                con.conname AS constraint_name,
                pg_get_constraintdef(con.oid) AS constraint_definition
            FROM pg_constraint con
            JOIN pg_class cl ON cl.oid = con.conrelid
            JOIN pg_namespace ns ON ns.oid = con.connamespace
            WHERE con.contype = 'f'
            AND NOT (pg_get_constraintdef(con.oid) ILIKE '%ON DELETE CASCADE%')
            AND (pg_get_constraintdef(con.oid) ILIKE '%REFERENCES auth.users%');
        """)
        others = cur.fetchall()
        for schema, table, cname, cdef in others:
            print(f"Fixing extra blocker: {table} ({cname})...")
            cur.execute(f'ALTER TABLE "{schema}"."{table}" DROP CONSTRAINT IF EXISTS "{cname}";')
            # Extract column name from definition e.g. FOREIGN KEY (user_id) -> user_id
            col_part = cdef.split('(')[1].split(')')[0]
            cur.execute(f'ALTER TABLE "{schema}"."{table}" ADD CONSTRAINT "{cname}" FOREIGN KEY ({col_part}) REFERENCES auth.users(id) ON DELETE CASCADE;')
            print("SUCCESS")

        cur.close()
        conn.close()
        print("\n--- REPAIR COMPLETE ---")
        
    except Exception as e:
        print(f"Database Error: {e}")

if __name__ == "__main__":
    final_fix()
