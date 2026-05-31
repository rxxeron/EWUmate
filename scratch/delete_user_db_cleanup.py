import os
import re
import sys
import subprocess

# Ensure psycopg2 is installed
try:
    import psycopg2
except ImportError:
    print("Installing psycopg2-binary...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "psycopg2-binary"])
    import psycopg2

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"
USER_ID = "6a22b9c4-2d2a-4ab6-bac3-a8a9cea039f4"

def main():
    print(f"Connecting to database to prune user ID: {USER_ID}...")
    try:
        conn = psycopg2.connect(DATABASE_URL)
        conn.autocommit = True
        cur = conn.cursor()
        
        # We need to find all tables that might have foreign keys pointing to public.profiles or auth.users
        # and delete rows where user_id or id matches the USER_ID.
        # Let's inspect the tables first or do a broad delete on tables we know:
        # e.g., user_courses, schedules, tasks, profiles, etc.
        
        tables_to_clean = [
            ("public.user_courses", "user_id"),
            ("public.schedules", "user_id"),
            ("public.tasks", "user_id"),
            ("public.profiles", "id")
        ]
        
        for table, col in tables_to_clean:
            try:
                cur.execute(f"DELETE FROM {table} WHERE {col} = %s;", (USER_ID,))
                print(f"Cleaned up rows in {table} where {col} = {USER_ID}")
            except Exception as e:
                print(f"Could not clean up {table}: {e}")
                
        # Now delete from auth.users
        print("Deleting from auth.users...")
        cur.execute("DELETE FROM auth.users WHERE id = %s;", (USER_ID,))
        print(f"Successfully deleted user ID {USER_ID} from auth.users!")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Database error: {e}")

if __name__ == "__main__":
    main()
