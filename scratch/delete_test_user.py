import requests
import subprocess
import sys

# Ensure psycopg2 is installed
try:
    import psycopg2
except ImportError:
    print("Installing psycopg2-binary...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "psycopg2-binary"])
    import psycopg2

# Credentials
URL = "https://jwygjihrbwxhehijldiz.supabase.co/auth/v1/admin/users"
KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY"
DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

HEADERS = {
    "apikey": KEY,
    "Authorization": f"Bearer {KEY}"
}

EMAIL_TO_DELETE = "2025-2-50-009@std.ewubd.edu"

def main():
    print(f"Fetching users list to locate: {EMAIL_TO_DELETE}...")
    res = requests.get(URL, headers=HEADERS)
    if res.status_code != 200:
        print(f"Failed to fetch users: {res.status_code} - {res.text}")
        return

    users_data = res.json()
    users = users_data.get("users", [])
    
    target_user = None
    for u in users:
        if u.get("email") == EMAIL_TO_DELETE:
            target_user = u
            break

    if not target_user:
        print(f"User with email '{EMAIL_TO_DELETE}' was not found in Auth.")
        return

    user_id = target_user["id"]
    print(f"Found user. ID: {user_id}. Connecting to database to clean up dependencies...")

    try:
        conn = psycopg2.connect(DATABASE_URL)
        conn.autocommit = True
        cur = conn.cursor()
        
        # Clean up database relations that might hold foreign keys
        tables_to_clean = [
            ("public.tasks", "user_id"),
            ("public.profiles", "id")
        ]
        
        for table, col in tables_to_clean:
            try:
                cur.execute(f"DELETE FROM {table} WHERE {col} = %s;", (user_id,))
                print(f"  Cleaned up {table} rows.")
            except Exception as e:
                print(f"  Could not clean up {table}: {e}")
                
        # Now delete from auth.users
        print("Deleting from auth.users table...")
        cur.execute("DELETE FROM auth.users WHERE id = %s;", (user_id,))
        print(f"Successfully deleted user '{EMAIL_TO_DELETE}' (ID: {user_id}) from database auth!")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Database error during deletion: {e}")

if __name__ == "__main__":
    main()
