import requests

URL_METADATA = "https://jwygjihrbwxhehijldiz.supabase.co/rest/v1/course_metadata"
URL_SPRING = "https://jwygjihrbwxhehijldiz.supabase.co/rest/v1/courses_spring2026"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"
HEADERS = {
    "apikey": KEY,
    "Authorization": f"Bearer {KEY}",
    "Content-Type": "application/json"
}

print("Fetching course metadata...")
res_metadata = requests.get(f"{URL_METADATA}?select=code,name,credit_val", headers=HEADERS)
metadata = res_metadata.json()
meta_map = { m["code"]: m for m in metadata }
print(f"Loaded {len(meta_map)} courses from metadata.")

print("Fetching courses from spring 2026...")
res_spring = requests.get(f"{URL_SPRING}?select=id,course_code,course_name,credit_val", headers=HEADERS)
spring_courses = res_spring.json()
print(f"Loaded {len(spring_courses)} courses from spring 2026.")

updates = []

for c in spring_courses:
    code = c["course_code"]
    name = c.get("course_name")
    credits_val = c.get("credit_val")

    needs_update = False
    update_payload = {}
    
    # 1. Name Missing?
    if not name or str(name).strip() == "" or str(name).strip().lower() == "null" or str(name).strip().lower() == "none":
        if code in meta_map and meta_map[code].get("name"):
            update_payload["course_name"] = meta_map[code]["name"]
            needs_update = True
            
    # 2. Credit Missing?
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
        updates.append({
            "id": c["id"],
            "course_code": code,
            "payload": update_payload
        })

print(f"Found {len(updates)} courses in `courses_spring2026` needing name/credit_val updates.")

success_count = 0
for u in updates:
    patch_res = requests.patch(
        f"{URL_SPRING}?id=eq.{u['id']}",
        headers=HEADERS,
        json=u["payload"]
    )
    if patch_res.status_code in [200, 204]:
        success_count += 1
    else:
        print(f"Failed to update {u['course_code']} (ID: {u['id']}): {patch_res.status_code} - {patch_res.text}")

print(f"\nSuccessfully updated {success_count} course records in `courses_spring2026`.")
