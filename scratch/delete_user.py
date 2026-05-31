import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def delete_user():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        email = '2025-2-50-009@std.ewubd.edu'
        
        # 1. Fetch user ID to make sure it exists
        cur.execute("SELECT id FROM auth.users WHERE email = %s;", (email,))
        row = cur.fetchone()
        
        if not row:
            print(f"User {email} not found in database.")
            cur.close()
            conn.close()
            return
            
        user_id = row[0]
        print(f"Found user {email} with ID: {user_id}")
        
        # 2. Delete from profiles (just in case cascade is not set up, though it usually is)
        print("Deleting from public.profiles...")
        cur.execute("DELETE FROM public.profiles WHERE id = %s;", (user_id,))
        
        # 3. Delete from auth.users
        print("Deleting from auth.users...")
        cur.execute("DELETE FROM auth.users WHERE id = %s;", (user_id,))
        
        conn.commit()
        print(f"Successfully deleted user {email} and their profile from the database!")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error deleting user: {e}")

if __name__ == "__main__":
    delete_user()
