import psycopg2

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def find_blocking_fks():
    try:
        conn = psycopg2.connect(conn_url)
        cur = conn.cursor()
        
        print("--- DISCOVERING ALL BLOCKING FOREIGN KEYS ---")
        
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
            AND NOT (pg_get_constraintdef(con.oid) ILIKE '%ON DELETE CASCADE%');
        """)
        
        fks = cur.fetchall()
        for schema, table, cname, cdef in fks:
            # We are interested in things pointing to users, profiles, etc.
            if any(target in cdef.lower() for target in ['users', 'profiles', 'semester', 'course']):
                print(f"[BLOCKING] {schema}.{table} | {cname} | {cdef}")

        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Database Error: {e}")

if __name__ == "__main__":
    find_blocking_fks()
