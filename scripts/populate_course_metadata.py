import json
import requests
import os
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
JSON_SOURCE = r"C:\Users\Farzana Safa\Downloads\all_courses_combined.json"
BACKUP_FILE = r"d:\EWUmate\EWUmate_Clean\ewumate_v2\scripts\backup_course_metadata.json"

def get_headers():
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json"
    }

def backup_metadata():
    print("Performing backup of course_metadata...")
    url = f"{SUPABASE_URL}/rest/v1/course_metadata?select=*"
    res = requests.get(url, headers=get_headers())
    if res.status_code == 200:
        data = res.json()
        with open(BACKUP_FILE, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=4)
        print(f"Backup saved to {BACKUP_FILE} ({len(data)} rows)")
        return True
    else:
        print(f"Error during backup: {res.status_code} - {res.text}")
        return False

def populate_metadata():
    if not SUPABASE_URL or not SUPABASE_KEY:
        print("Error: Missing Supabase credentials in .env")
        return

    # 1. Backup first (assuming already done but we can do it again)
    backup_metadata()

    # 2. Read New JSON
    print(f"Reading {JSON_SOURCE}...")
    try:
        with open(JSON_SOURCE, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error reading source file: {e}")
        return
    
    print(f"Loaded {len(data)} courses from source.")

    # 3. Clean Table
    # NOTE: Cleanup will fail if self-referencing FKs exist and aren't CASCADE.
    # But usually a full delete works if no OUTER tables reference it.
    print("Cleaning course_metadata table...")
    # We might need to clear equivalent_code first to avoid FK issues on delete?
    # Actually, a full delete of all rows in one transaction usually works.
    delete_url = f"{SUPABASE_URL}/rest/v1/course_metadata"
    res_del = requests.delete(f"{delete_url}?code=neq.DUMMY_NONE_EXISTENT", headers=get_headers())
    
    if res_del.status_code not in [200, 204]:
        print(f"Error during cleaning: {res_del.status_code}: {res_del.text}")
        # If it failed due to FKs, let's try clearing the refs first
        print("Attempting to clear equivalent_code references before deletion...")
        requests.patch(delete_url, headers=get_headers(), json={"equivalent_code": None})
        res_del = requests.delete(f"{delete_url}?code=neq.DUMMY_NONE_EXISTENT", headers=get_headers())
        if res_del.status_code not in [200, 204]:
             print("Cleanup failed again. Aborting.")
             return

    # 4. Two-Pass Insertion
    print("Starting Two-Pass Insertion...")
    
    # PASS 1: Base Data (No FKs)
    print("Pass 1: Inserting rows without equivalent_code...")
    base_rows = []
    for item in data:
        base_rows.append({
            "code": item.get("course_code"),
            "name": item.get("course_name"),
            "credit_val": item.get("credits", 3.0),
            "equivalent_code": None
        })
    
    headers = get_headers()
    headers["Prefer"] = "return=minimal"
    
    batch_size = 500
    for i in range(0, len(base_rows), batch_size):
        batch = base_rows[i:i + batch_size]
        res = requests.post(f"{SUPABASE_URL}/rest/v1/course_metadata", headers=headers, json=batch)
        if res.status_code not in [201, 200]:
            print(f"Error in Pass 1 batch {i}: {res.text}")
            return

    # PASS 2: Update FKs
    print("Pass 2: Updating equivalent_code references...")
    update_count = 0
    for item in data:
        eq_code = item.get("equivalent_course_code")
        if eq_code:
            code = item.get("course_code")
            # We can use PATCH for each, or batch it if possible (PostgREST batch update is hard)
            # For 476 items, individual patches are fast enough
            res = requests.patch(
                f"{SUPABASE_URL}/rest/v1/course_metadata?code=eq.{code}", 
                headers=headers, 
                json={"equivalent_code": eq_code}
            )
            if res.status_code not in [200, 204]:
                print(f"Warning: Failed to set equivalent_code for {code}: {res.text}")
            else:
                update_count += 1
    
    print(f"Successfully updated {update_count} equivalent codes.")
    print("Population complete.")

if __name__ == "__main__":
    populate_metadata()
