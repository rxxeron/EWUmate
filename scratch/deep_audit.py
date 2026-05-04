import psycopg2

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def deep_audit():
    try:
        conn = psycopg2.connect(conn_url)
        cur = conn.cursor()
        
        print("--- DEEP AUDIT: FINDING BLOCKING CONSTRAINTS ---")
        
        cur.execute("""
            SELECT
                tc.table_name, 
                rc.delete_rule,
                tc.constraint_name
            FROM 
                information_schema.table_constraints AS tc 
                JOIN information_schema.referential_constraints AS rc
                  ON tc.constraint_name = rc.constraint_name
                JOIN information_schema.constraint_column_usage AS ccu
                  ON rc.unique_constraint_name = ccu.constraint_name
            WHERE tc.constraint_type = 'FOREIGN KEY' 
            AND ccu.table_schema = 'auth'
            AND ccu.table_name = 'users'
            AND rc.delete_rule != 'CASCADE';
        """)
        
        blocking = cur.fetchall()
        if not blocking:
            print("No DIRECT blocking constraints found for auth.users.")
        else:
            print(f"Found {len(blocking)} DIRECT blocking constraints:")
            for table, rule, cname in blocking:
                print(f" - Table: {table} | Rule: {rule} | Constraint: {cname}")

        # Now check for INDIRECT blocking (tables pointing to tables that point to auth.users)
        print("\n--- CHECKING INDIRECT BLOCKING (Pointing to Profiles) ---")
        cur.execute("""
            SELECT
                tc.table_name, 
                rc.delete_rule,
                tc.constraint_name
            FROM 
                information_schema.table_constraints AS tc 
                JOIN information_schema.referential_constraints AS rc
                  ON tc.constraint_name = rc.constraint_name
                JOIN information_schema.constraint_column_usage AS ccu
                  ON rc.unique_constraint_name = ccu.constraint_name
            WHERE tc.constraint_type = 'FOREIGN KEY' 
            AND ccu.table_schema = 'public'
            AND ccu.table_name = 'profiles'
            AND rc.delete_rule != 'CASCADE';
        """)
        
        indirect = cur.fetchall()
        if not indirect:
            print("No INDIRECT blocking constraints found for profiles.")
        else:
            print(f"Found {len(indirect)} INDIRECT blocking constraints:")
            for table, rule, cname in indirect:
                print(f" - Table: {table} | Rule: {rule} | Constraint: {cname}")

        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Database Error: {e}")

if __name__ == "__main__":
    deep_audit()
