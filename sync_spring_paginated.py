import requests
import json

URL_METADATA = "https://jwygjihrbwxhehijldiz.supabase.co/rest/v1/course_metadata"
URL_SPRING = "https://jwygjihrbwxhehijldiz.supabase.co/rest/v1/courses_spring2026"
KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY"
HEADERS = {
    "apikey": KEY,
    "Authorization": f"Bearer {KEY}",
    "Content-Type": "application/json"
}

def fetch_all_rows(url, select_fields):
    all_data = []
    offset = 0
    limit = 1000
    while True:
        res = requests.get(f"{url}?select={select_fields}&offset={offset}&limit={limit}", headers=HEADERS)
        data = res.json()
        if not isinstance(data, list):
            print(f"Error fetching data: {data}")
            break
        all_data.extend(data)
        if len(data) < limit:
            break
        offset += limit
    return all_data

metadata = fetch_all_rows(URL_METADATA, "code,name,credit_val")
meta_map = { m["code"]: m for m in metadata }
print(f"Loaded {len(meta_map)} metadata entries (Total rows: {len(metadata)}).")

spring_courses = fetch_all_rows(URL_SPRING, "id,course_code,course_name,credit_val")
print(f"Loaded {len(spring_courses)} full courses from spring 2026.")

updates = []
for c in spring_courses:
    code = c["course_code"]
    name = c.get("course_name")
    credits_val = c.get("credit_val")
    needs_update = False
    update_payload = {}
    
    if not name or str(name).strip() == "" or str(name).strip().lower() == "null" or str(name).strip().lower() == "none":
        if code in meta_map and meta_map[code].get("name"):
            update_payload["course_name"] = meta_map[code]["name"]
            needs_update = True
            
    needs_credits = False
    if credits_val is None or str(credits_val).strip() == "":
        needs_credits = True
    else:
        try:
            if float(credits_val) == 0:
                needs_credits = True
        except ValueError:
            needs_credits = True
            
    if needs_credits:
        if code in meta_map and meta_map[code].get("credit_val") is not None:
            update_payload["credit_val"] = meta_map[code]["credit_val"]
            needs_update = True
            
    if needs_update:
        updates.append({"id": c["id"], "course_code": code, "payload": update_payload})

print(f"Found {len(updates)} remaining courses needing updates out of the total {len(spring_courses)}.")
success_count = 0
for u in updates:
    patch_res = requests.patch(f"{URL_SPRING}?id=eq.{u['id']}", headers=HEADERS, json=u["payload"])
    if patch_res.status_code in [200, 204]:
        success_count += 1
print(f"Successfully updated {success_count} course records.")
