import psycopg2
import json

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def inspect_user_by_id(user_id):
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        print(f"--- Inspecting User ID: {user_id} ---")
        
        # 1. Profile check - select all to see column names
        cur.execute("SELECT * FROM public.profiles WHERE id = %s", (user_id,))
        colnames = [desc[0] for desc in cur.description]
        profile = cur.fetchone()
        if profile:
            profile_dict = dict(zip(colnames, profile))
            print("--- Profile Data ---")
            for k, v in profile_dict.items():
                if k not in ['academic_data']: # Skip potentially huge blobs
                    print(f"{k}: {v}")
        else:
            print("Profile not found!")

        # 2. Enrollments check
        print("\n--- Enrollments ---")
        cur.execute("SELECT * FROM public.enrollments WHERE user_id = %s", (user_id,))
        colnames = [desc[0] for desc in cur.description]
        enrollments = cur.fetchall()
        for e in enrollments:
            e_dict = dict(zip(colnames, e))
            print(e_dict)

        # 3. Tables count
        print("\n--- Row counts in public tables ---")
        cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
        tables = [t[0] for t in cur.fetchall()]
        for tname in tables:
            try:
                cur.execute(f"SELECT count(*) FROM public.{tname} WHERE user_id = %s", (user_id,))
                count = cur.fetchone()[0]
                if count > 0:
                    print(f"{tname}: {count}")
            except:
                conn.rollback()

        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    inspect_user_by_id("191aaf7c-9004-4164-9da0-518169b25d18")
