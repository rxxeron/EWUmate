import psycopg2
import psycopg2.extras
from dotenv import load_dotenv
import os
import json

def main():
    load_dotenv()
    db_url = os.environ.get('DATABASE_URL')
    if not db_url:
        print("Error: DATABASE_URL not found in .env")
        return

    print("Connecting to PROD database (READ-ONLY mode)...")
    conn = psycopg2.connect(db_url)
    conn.set_client_encoding('UTF8')
    # Use DictCursor to get column names easily
    cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    # 1. Get all base tables in public schema
    cur.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
          AND table_type = 'BASE TABLE'
    """)
    tables = [row[0] for row in cur.fetchall()]

    print(f"Found {len(tables)} tables to export.")

    with open('supabase/seed.sql', 'w', encoding='utf-8') as f:
        f.write("-- Supabase Seed Data (Exported from PROD)\n")
        f.write("SET session_replication_role = 'replica';\n\n")

        for table in tables:
            print(f"Exporting table: {table}...")
            
            # Fetch column names and types for this table
            cur.execute("""
                SELECT column_name, data_type 
                FROM information_schema.columns 
                WHERE table_schema = 'public' 
                  AND table_name = %s
                ORDER BY ordinal_position
            """, (table,))
            columns_info = cur.fetchall()
            
            if not columns_info:
                print(f"  Warning: No columns found for {table}")
                continue

            active_columns = [col['column_name'] for col in columns_info]
            col_meta = {col['column_name']: col['data_type'] for col in columns_info}
            col_names_str = ", ".join(f'"{c}"' for c in active_columns)
            
            # Fetch data using the specific columns we found
            cur.execute(f'SELECT {col_names_str} FROM "public"."{table}"')
            rows = cur.fetchall()
            
            if not rows:
                print(f"  No data in {table}")
                continue

            f.write(f"-- Data for {table}\n")
            batch_size = 50
            for i in range(0, len(rows), batch_size):
                batch = rows[i:i + batch_size]
                f.write(f'INSERT INTO "public"."{table}" ({col_names_str}) VALUES\n')
                
                values_list = []
                for row in batch:
                    vals = []
                    for col in active_columns:
                        val = row[col]
                        c_type = col_meta.get(col)
                        
                        if val is None:
                            vals.append("NULL")
                        elif c_type == 'ARRAY':
                            # Use psycopg2's default array formatting
                            mogrified = cur.mogrify('%s', (val,)).decode('utf-8')
                            vals.append(mogrified)
                        elif isinstance(val, (dict, list)) or c_type in ('json', 'jsonb'):
                            # Use Json helper for complex types
                            mogrified = cur.mogrify('%s', (psycopg2.extras.Json(val),)).decode('utf-8')
                            vals.append(mogrified)
                        else:
                            # Standard types
                            mogrified = cur.mogrify('%s', (val,)).decode('utf-8')
                            vals.append(mogrified)
                    values_list.append("(" + ", ".join(vals) + ")")
                
                f.write(",\n".join(values_list) + ";\n")
            f.write("\n")

        f.write("SET session_replication_role = 'origin';\n")

    cur.close()
    conn.close()
    print("Done! Data exported to supabase/seed.sql")

if __name__ == "__main__":
    main()
