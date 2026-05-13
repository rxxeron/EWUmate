import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv(r"d:\EWUmate\EWUmate_Clean\ewumate_v2\Assignment\.env")

url = os.environ.get("VITE_SUPABASE_URL")
key = os.environ.get("VITE_SUPABASE_ANON_KEY")
supabase = create_client(url, key)

def check_schema():
    print("Checking faculty table schema...")
    try:
        # Get one record to see columns
        res = supabase.table("faculty").select("*").limit(1).execute()
        if res.data:
            print(f"Columns: {list(res.data[0].keys())}")
        else:
            print("No data in faculty table to inspect.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_schema()
