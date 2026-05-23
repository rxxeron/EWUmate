import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

target_emails = [
    "2026210121@std.ewubd.edu",
    "2056-2-60-517@std.ewubd.edu",
    "tester1@std.ewubd.edu",
    "saifulislamalamin321@std.ewubd.edu",
    "adnananik@gmail.com",
    "2026-260-517@std.ewubd.edu",
    "prapti@std.ewubd.edu",
    "2025-2-60-345@std.ewubd.eud",
    "2025-3-27@std.ewubd.edu",
    "2026-2-60-517-@std.ewubd.edu"
]

def inspect():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    print("--- Checking auth.users for target emails ---")
    placeholders = ", ".join(["%s"] * len(target_emails))
    cur.execute(f"""
        SELECT id, email, created_at 
        FROM auth.users 
        WHERE email IN ({placeholders});
    """, target_emails)
    users = cur.fetchall()
    
    user_ids = []
    print(f"Found {len(users)} users out of {len(target_emails)} target emails:")
    for uid, email, created_at in users:
        print(f"ID: {uid} | Email: {email} | Created At: {created_at}")
        user_ids.append(uid)
        
    if not user_ids:
        print("No users found matching these emails.")
        cur.close()
        conn.close()
        return

    # Find foreign keys referencing auth.users or profiles
    print("\n--- Checking for foreign key constraints ---")
    cur.execute("""
        SELECT
            tc.table_schema, 
            tc.table_name, 
            kcu.column_name, 
            ccu.table_schema AS foreign_table_schema,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name 
        FROM 
            information_schema.table_constraints AS tc 
            JOIN information_schema.key_column_usage AS kcu
              ON tc.constraint_name = kcu.constraint_name
              AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage AS ccu
              ON ccu.constraint_name = tc.constraint_name
              AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND (ccu.table_name = 'users' AND ccu.table_schema = 'auth' 
               OR ccu.table_name = 'profiles' AND ccu.table_schema = 'public');
    """)
    fks = cur.fetchall()
    for fk in fks:
        print(f"Table: {fk[0]}.{fk[1]} ({fk[2]}) -> References: {fk[3]}.{fk[4]} ({fk[5]})")

    # Now let's inspect the count of records for these user IDs in various public tables
    print("\n--- Inspecting related records for these users ---")
    # Let's get a list of all tables in the public schema
    cur.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public';
    """)
    public_tables = [r[0] for r in cur.fetchall()]
    
    for table in public_tables:
        # Check if the table has a column like 'user_id', 'profile_id', 'id', 'uploader_id'
        cur.execute(f"""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = %s AND table_schema = 'public';
        """, (table,))
        cols = [r[0] for r in cur.fetchall()]
        
        for col in cols:
            if col in ['user_id', 'id', 'uploader_id', 'profile_id']:
                # Let's count records for our user_ids
                try:
                    cur.execute(f"SELECT COUNT(*) FROM public.{table} WHERE {col} IN ({', '.join(['%s']*len(user_ids))})", user_ids)
                    count = cur.fetchone()[0]
                    if count > 0:
                        print(f"Table public.{table} has {count} records matching {col} in our target list.")
                except Exception as e:
                    # In case of type mismatch or other issues
                    conn.rollback()
                    
    cur.close()
    conn.close()

if __name__ == "__main__":
    inspect()
