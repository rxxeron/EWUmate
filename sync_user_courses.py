import requests
import json
import re

URL_METADATA = "https://jwygjihrbwxhehijldiz.supabase.co/rest/v1/course_metadata"
URL_ENROLLMENTS = "https://jwygjihrbwxhehijldiz.supabase.co/rest/v1/enrollments"
URL_COMPLETED = "https://jwygjihrbwxhehijldiz.supabase.co/rest/v1/completed_courses"
KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY"
HEADERS = {"apikey": KEY, "Authorization": f"Bearer {KEY}", "Content-Type": "application/json"}

def fetch_all(url, select="*"):
    all_data = []
    offset, limit = 0, 1000
    while True:
        res = requests.get(f"{url}?select={select}&offset={offset}&limit={limit}", headers=HEADERS)
        data = res.json()
        if not isinstance(data, list):
            print(f"Error fetching data: {data}")
            break
        all_data.extend(data)
        if len(data) < limit:
            break
        offset += limit
    return all_data

# Fetch Metadata
metadata = fetch_all(URL_METADATA, "code,credit_val,equivalent_code")
meta_map = {m["code"]: m for m in metadata}

def sanitize_code(c_str):
    if not c_str:
        return c_str
    new_c = c_str.replace("-", "")
    match = re.match(r"^([A-Za-z]+)9(\d{3})$", new_c)
    if match:
        new_c = match.group(1) + match.group(2)
    return new_c

# 1. Update Enrollments
print("Fetching enrollments...")
enrollments = fetch_all(URL_ENROLLMENTS, "id,course_code,user_id")
print(f"Loaded {len(enrollments)} enrollments.")

enrollment_updates = []
impacted_users = set()

for e in enrollments:
    orig = e.get("course_code")
    new_code = sanitize_code(orig)
    if new_code != orig:
        enrollment_updates.append({"id": e["id"], "course_code": new_code})
        impacted_users.add(e["user_id"])

print(f"Found {len(enrollment_updates)} enrollments with bad course codes.")
success_count = 0
for u in enrollment_updates:
    res = requests.patch(f"{URL_ENROLLMENTS}?id=eq.{u['id']}", headers=HEADERS, json={"course_code": u["course_code"]})
    if res.status_code in [200, 204]:
        success_count += 1
print(f"Successfully updated {success_count} enrollments.")

# 2. Update Completed Courses
print("\nFetching completed courses...")
completed = fetch_all(URL_COMPLETED, "id,course_code,credits,user_id")
print(f"Loaded {len(completed)} completed courses.")

completed_updates = []
for c in completed:
    orig = c.get("course_code")
    new_code = sanitize_code(orig)
    current_credits = c.get("credits")
    
    payload = {}
    needs_update = False
    
    if new_code != orig:
        payload["course_code"] = new_code
        needs_update = True
        
    # Check if credits need update compared to metadata
    lookup_code = new_code if new_code else orig
    proper_credits = None
    if lookup_code in meta_map:
        proper_credits = meta_map[lookup_code]["credit_val"]
        
    is_missing_credits = False
    if current_credits is None or str(current_credits).strip() == "":
        is_missing_credits = True
    else:
        try:
            if float(current_credits) == 0:
                is_missing_credits = True
        except ValueError:
            is_missing_credits = True

    if is_missing_credits and proper_credits is not None:
        payload["credits"] = proper_credits
        needs_update = True
        
    if needs_update:
        completed_updates.append({"id": c["id"], "payload": payload})
        impacted_users.add(c["user_id"])

print(f"Found {len(completed_updates)} completed courses needing updates.")
success_count = 0
for u in completed_updates:
    res = requests.patch(f"{URL_COMPLETED}?id=eq.{u['id']}", headers=HEADERS, json=u["payload"])
    if res.status_code in [200, 204]:
        success_count += 1
print(f"Successfully updated {success_count} completed courses.")

# 3. Synchronize
print(f"\nTriggering sync functions for {len(impacted_users)} impacted users...")
SYNC_ACADEMIC_URL = "https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-academic-stats"
SYNC_SCHEDULE_URL = "https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-schedule"

sync_count = 0
for uid in impacted_users:
    requests.post(SYNC_ACADEMIC_URL, headers=HEADERS, json={"user_id": uid})
    requests.post(SYNC_SCHEDULE_URL, headers=HEADERS, json={"user_id": uid})
    sync_count += 1

print(f"Sent sync events for {sync_count} users! Update complete.")
