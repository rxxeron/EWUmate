import os
import re
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))

def clean_name(name):
    if not name: return ""
    name = name.strip()
    # Remove Mr/Ms/Mrs prefixes
    name = re.sub(r'^(Mr|Ms|Mrs)\.?\s+', '', name, flags=re.IGNORECASE)
    # Title Case
    return name.title()

print("Fetching all faculty records...")
res = sb.table("faculty_master").select("id, full_name, email").execute()
faculty_list = res.data

print(f"Cleaning {len(faculty_list)} records...")
updates = []
for f in faculty_list:
    new_name = clean_name(f['full_name'])
    new_email = (f.get('email') or "").lower().strip()
    
    if new_name != f['full_name'] or new_email != f.get('email'):
        updates.append({
            "id": f['id'],
            "full_name": new_name,
            "email": new_email
        })

if updates:
    print(f"Applying {len(updates)} updates...")
    # Batch updates in chunks of 50 to avoid timeout
    for i in range(0, len(updates), 50):
        chunk = updates[i:i+50]
        for item in chunk:
            sb.table("faculty_master").update({
                "full_name": item["full_name"],
                "email": item["email"]
            }).eq("id", item["id"]).execute()
    print("Cleanup complete!")
else:
    print("No updates needed.")
