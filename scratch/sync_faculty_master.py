import os
import json
import re
from supabase import create_client
from dotenv import load_dotenv

# Load from root folder to get Service Role Key
load_dotenv(r"d:\EWUmate\EWUmate_Clean\ewumate_v2\.env")

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not url or not key:
    print("Error: Missing credentials in root .env")
    exit()

supabase = create_client(url, key)

JSON_FILE = r"d:\EWUmate\EWUmate_Clean\ewumate_v2\scratch\faculty_master_data.json"

def sync_master_data():
    if not os.path.exists(JSON_FILE):
        print(f"Error: {JSON_FILE} not found.")
        return

    with open(JSON_FILE, 'r', encoding='utf-8') as f:
        master_data = json.load(f)

    print(f"Loaded {len(master_data)} records from JSON.")
    
    # 1. Fetch all existing faculty from DB to match by name
    print("Fetching existing faculty from DB...")
    db_res = supabase.table("faculty_master").select("id, full_name, short_name").execute()
    db_faculty = db_res.data
    print(f"Found {len(db_faculty)} faculty in database.")
    print("Sample DB Data:", [{"short": f['short_name'], "full": f['full_name']} for f in db_faculty[:10]])

    # Create a mapping of clean names to DB records
    def clean_name(n): 
        # Remove common titles
        n = re.sub(r'^(Dr|Prof|Engr|Mr|Ms|Mrs)\.?\s+', '', n, flags=re.IGNORECASE)
        # Remove all non-alphanumeric
        return "".join(c for c in n.lower() if c.isalnum())
    
    name_map = {clean_name(f['full_name']): f for f in db_faculty}
    
    updates = 0
    not_found = 0

    for item in master_data:
        name = item['full_name']
        c_name = clean_name(name)
        
        if c_name in name_map:
            db_record = name_map[c_name]
            
            # Update photo_url and designation_name
            try:
                supabase.table("faculty_master").update({
                    "photo_url": item['photo_url'],
                    "designation_name": item['designation'],
                    "profile_url": item['profile_url'], # Adding this too
                    "updated_at": "now()"
                }).eq("id", db_record['id']).execute()
                updates += 1
                if updates % 10 == 0:
                    print(f"Updated {updates} records...")
            except Exception as e:
                print(f"Error updating {name}: {e}")
        else:
            not_found += 1
            # print(f"Not found in DB: {name}")

    print(f"\nSync Complete!")
    print(f"Total Matches Updated: {updates}")
    print(f"Faculty not found in DB: {not_found}")

if __name__ == "__main__":
    sync_master_data()
