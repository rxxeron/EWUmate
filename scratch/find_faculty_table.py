import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv(r"d:\EWUmate\EWUmate_Clean\ewumate_v2\Assignment\.env")

url = os.environ.get("VITE_SUPABASE_URL")
key = os.environ.get("VITE_SUPABASE_ANON_KEY")
supabase = create_client(url, key)

def list_tables():
    print("Checking tables...")
    try:
        # Try a few common names
        for table in ["faculty", "faculty_master", "faculties", "faculty_directory"]:
            try:
                res = supabase.table(table).select("*").limit(1).execute()
                print(f"Table '{table}' found! Columns: {list(res.data[0].keys()) if res.data else 'Empty'}")
            except Exception as e:
                print(f"Table '{table}' not found.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    list_tables()
