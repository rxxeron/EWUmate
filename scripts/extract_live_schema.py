import psycopg2
import json
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

def get_live_schema():
    print(f"Connecting to live database...")
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        # 1. Get all tables in the public schema
        cur.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)
        tables = [row[0] for row in cur.fetchall()]
        
        schema_data = {"tables": {}}
        
        for table in tables:
            print(f"Fetching schema for table: {table}")
            # Get columns for each table
            cur.execute(f"""
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns
                WHERE table_name = '{table}' AND table_schema = 'public'
                ORDER BY ordinal_position;
            """)
            columns = cur.fetchall()
            schema_data["tables"][table] = [
                {"column": col[0], "type": col[1], "nullable": col[2], "default": col[3]}
                for col in columns
            ]
            
        # 2. Get all functions in the public schema
        print("Fetching functions...")
        cur.execute("""
            SELECT 
                p.proname as function_name,
                pg_get_function_arguments(p.oid) as arguments,
                pg_get_functiondef(p.oid) as definition
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public'
            ORDER BY p.proname;
        """)
        functions = cur.fetchall()
        schema_data["functions"] = [
            {"name": func[0], "args": func[1], "definition": func[2]}
            for func in functions
        ]
        
        # 3. Get all triggers
        print("Fetching triggers...")
        cur.execute("""
            SELECT 
                trigger_name,
                event_object_table as table_name,
                action_statement as definition,
                action_timing as timing,
                event_manipulation as event
            FROM information_schema.triggers
            WHERE trigger_schema = 'public'
            ORDER BY trigger_name;
        """)
        triggers = cur.fetchall()
        schema_data["triggers"] = [
            {"name": trig[0], "table": trig[1], "definition": trig[2], "timing": trig[3], "event": trig[4]}
            for trig in triggers
        ]

        # Save to JSON file
        output_file = "docs/knowledge/live_schema_dump.json"
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        with open(output_file, "w") as f:
            json.dump(schema_data, f, indent=4)
            
        print(f"Successfully exported live schema to {output_file}")
        
    except Exception as e:
        print(f"Error extracting schema: {e}")
    finally:
        if 'cur' in locals(): cur.close()
        if 'conn' in locals(): conn.close()

if __name__ == "__main__":
    get_live_schema()
