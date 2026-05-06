import psycopg2
import os
import json

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def get_schema():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        # Get all tables in public schema
        cur.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_type = 'BASE TABLE'
            ORDER BY table_name;
        """)
        tables = cur.fetchall()
        
        schema_info = {}
        
        for table in tables:
            table_name = table[0]
            # Get columns for each table
            cur.execute(f"""
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns
                WHERE table_schema = 'public'
                AND table_name = '{table_name}'
                ORDER BY ordinal_position;
            """)
            columns = cur.fetchall()
            schema_info[table_name] = [
                {
                    "name": col[0],
                    "type": col[1],
                    "nullable": col[2],
                    "default": col[3]
                } for col in columns
            ]
            
        cur.close()
        conn.close()
        return schema_info
    except Exception as e:
        return str(e)

if __name__ == "__main__":
    schema = get_schema()
    with open("scratch/schema_output.json", "w", encoding="utf-8") as f:
        json.dump(schema, f, indent=2)
    print("Schema dumped to scratch/schema_output.json")
