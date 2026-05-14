import psycopg2
import json

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def inspect_user(email):
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        # 1. Find user_id from auth.users (via profiles since we are using postgres role)
        print(f"--- Searching for user: {email} ---")
        cur.execute("SELECT id, email, full_name, onboarded_status, enrolled_sections FROM public.profiles WHERE email = %s", (email,))
        user = cur.fetchone()
        
        if not user:
            print("User not found in public.profiles")
            return
        
        user_id, user_email, name, status, enrolled_sections = user
        print(f"User ID: {user_id}")
        print(f"Name: {name}")
        print(f"Status: {status}")
        print(f"Enrolled Sections Array: {enrolled_sections}")
        
        # 2. Check enrollments table
        print("\n--- Enrollments in public.enrollments ---")
        cur.execute("SELECT semester_code, course_code, section_number, status FROM public.enrollments WHERE user_id = %s", (user_id,))
        enrollments = cur.fetchall()
        for e in enrollments:
            print(f"Sem: {e[0]} | Code: {e[1]} | Sec: {e[2]} | Status: {e[3]}")
            
        # 3. Check for the "duplicate key" issue
        print("\n--- Checking for potential unique constraint violations ---")
        cur.execute("""
            SELECT table_name
            FROM information_schema.columns
            WHERE column_name = 'user_id'
            AND table_schema = 'public'
            INTERSECT
            SELECT table_name
            FROM information_schema.columns
            WHERE column_name = 'semester_code'
            AND table_schema = 'public';
        """)
        common_tables = cur.fetchall()
        for table in common_tables:
            table_name = table[0]
            try:
                cur.execute(f"SELECT count(*) FROM public.{table_name} WHERE user_id = %s", (user_id,))
                count = cur.fetchone()[0]
                print(f"Table: {table_name} | Entries for this user: {count}")
                if count > 0:
                    cur.execute(f"SELECT * FROM public.{table_name} WHERE user_id = %s LIMIT 5", (user_id,))
                    rows = cur.fetchall()
                    print(f"Data: {rows}")
            except:
                conn.rollback()

        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    inspect_user("2025-2-50-041@std.ewubd.edu")
