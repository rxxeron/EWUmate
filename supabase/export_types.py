import psycopg2
import psycopg2.extras
from dotenv import load_dotenv
import os

def main():
    load_dotenv()
    db_url = os.environ.get('DATABASE_URL')
    if not db_url:
        print("Error: DATABASE_URL not found in .env")
        return

    print("Connecting to PROD database (READ-ONLY mode) to fetch types...")
    conn = psycopg2.connect(db_url)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    # Fetch ENUMs
    cur.execute("""
        SELECT 
            n.nspname as schema_name,
            t.typname as type_name,
            array_agg(e.enumlabel ORDER BY e.enumsortorder) as enum_values
        FROM pg_type t
        JOIN pg_enum e ON t.oid = e.enumtypid
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public'
        GROUP BY n.nspname, t.typname
    """)
    enums = cur.fetchall()

    with open('supabase/migrations/20260403000000_types.sql', 'w', encoding='utf-8') as f:
        f.write("-- Custom ENUM Types\n\n")
        for en in enums:
            vals = ", ".join(f"'{v}'" for v in en['enum_values'])
            f.write(f"CREATE TYPE public.\"{en['type_name']}\" AS ENUM ({vals});\n")

    cur.close()
    conn.close()
    print("Done! Types exported to supabase/migrations/20260403000000_types.sql")

if __name__ == "__main__":
    main()
