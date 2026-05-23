import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def main():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    # Query all triggers on the study_materials table
    cur.execute("""
        SELECT tgname, tgenabled, pg_get_triggerdef(pg_trigger.oid) 
        FROM pg_trigger 
        JOIN pg_class ON pg_class.oid = pg_trigger.tgrelid 
        WHERE pg_class.relname = 'study_materials';
    """)
    triggers = cur.fetchall()
    
    print("--- Triggers on 'study_materials' table in Supabase ---")
    for tgname, tgenabled, tgdef in triggers:
        # Ignore internal system triggers starting with "RI_ConstraintTrigger" to keep output readable
        if tgname.startswith("RI_ConstraintTrigger"):
            continue
        print(f"Trigger Name: {tgname}")
        print(f"Enabled: {tgenabled}")
        print(f"Definition: {tgdef}")
        print("-" * 50)
        
    cur.close()
    conn.close()

if __name__ == '__main__':
    main()
