import psycopg2

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def deep_fix_all():
    try:
        conn = psycopg2.connect(conn_url)
        conn.autocommit = True
        cur = conn.cursor()
        
        print("--- STARTING DEEP DATABASE FIX ---")
        
        # 1. Identify ALL foreign keys pointing to auth.users in ANY schema
        cur.execute("""
            SELECT
                tc.table_schema,
                tc.table_name, 
                kcu.column_name,
                tc.constraint_name
            FROM 
                information_schema.table_constraints AS tc 
                JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
                JOIN information_schema.referential_constraints AS rc ON tc.constraint_name = rc.constraint_name
                JOIN information_schema.constraint_column_usage AS ccu ON rc.unique_constraint_name = ccu.constraint_name
            WHERE tc.constraint_type = 'FOREIGN KEY' 
            AND ccu.table_schema = 'auth'
            AND ccu.table_name = 'users';
        """)
        
        fks = cur.fetchall()
        print(f"Found {len(fks)} links to users. Applying CASCADE to all...")
        
        for schema, table, col, cname in fks:
            try:
                print(f"Fixing {schema}.{table} ({cname})...")
                cur.execute(f'ALTER TABLE "{schema}"."{table}" DROP CONSTRAINT IF EXISTS "{cname}";')
                cur.execute(f'ALTER TABLE "{schema}"."{table}" ADD CONSTRAINT "{cname}" FOREIGN KEY ("{col}") REFERENCES auth.users(id) ON DELETE CASCADE;')
                print("SUCCESS")
            except Exception as e:
                print(f"FAILED for {table}: {e}")

        # 2. Specifically fix semester_course_marks if not caught
        print("\nVerifying semester_course_marks...")
        cur.execute("ALTER TABLE public.semester_course_marks DROP CONSTRAINT IF EXISTS semester_course_marks_user_id_fkey;")
        cur.execute("ALTER TABLE public.semester_course_marks ADD CONSTRAINT semester_course_marks_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;")
        print("SUCCESS")

        cur.close()
        conn.close()
        print("\n--- DEEP FIX COMPLETE ---")
        
    except Exception as e:
        print(f"Database Error: {e}")

if __name__ == "__main__":
    deep_fix_all()
