import urllib.request, json

url = "https://jwygjihrbwxhehijldiz.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"
headers = {"apikey": key, "Authorization": f"Bearer {key}", "Content-Type": "application/json"}

# 1. Load mappings
mapping = {}
for i in range(0, 3000, 1000):
   r = urllib.request.Request(f"{url}/rest/v1/courses_spring2026?select=id,course_code,section_number&limit=1000&offset={i}", headers=headers)
   try:
       with urllib.request.urlopen(r) as res:
           lst = json.loads(res.read().decode())
           if not lst: break
           for row in lst:
               mapping[f"{row['course_code']}_{row['section_number']}"] = row['id']
   except Exception as e: print(e)

# 2. Patch the requested user's broken ones
fixes = {
    'MAT102': '4',
    'ICE107': '12',
    'CHE109': '6',
    'ICE204': '14'
}

req = urllib.request.Request(f"{url}/rest/v1/enrollments?user_id=eq.374a09cd-c366-4eea-89cc-dbda99154c3e&semester_code=eq.Spring2026", headers=headers)
with urllib.request.urlopen(req) as res:
    user_enrolls = json.loads(res.read().decode())
    
    for e in user_enrolls:
        course = e['course_code']
        if course in fixes:
            sec = fixes[course]
            new_id = mapping.get(f"{course}_{sec}")
            
            if new_id:
                print(f"Patching {course} -> Section {sec} (New ID: {new_id})")
                patch_req = urllib.request.Request(
                    f"{url}/rest/v1/enrollments?id=eq.{e['id']}",
                    data=json.dumps({"section_id": new_id}).encode(),
                    headers=headers,
                    method="PATCH"
                )
                try:
                    urllib.request.urlopen(patch_req)
                    print(f"? Successfully patched {course}")
                except Exception as err:
                    print(f"? Failed to patch {course}: {err}")
            else:
                print(f"? Could not find {course} section {sec} in new mapping.")

