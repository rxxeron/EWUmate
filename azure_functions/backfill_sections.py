import urllib.request, json

url = "https://jwygjihrbwxhehijldiz.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"
headers = {"apikey": key, "Authorization": f"Bearer {key}", "Content-Type": "application/json"}

# 1. Build mapping of ID -> section_number
id_to_section = {}
for i in range(0, 3000, 1000):
   r = urllib.request.Request(f"{url}/rest/v1/courses_spring2026?select=id,section_number&limit=1000&offset={i}", headers=headers)
   try:
       with urllib.request.urlopen(r) as res:
           lst = json.loads(res.read().decode())
           if not lst: break
           for row in lst:
               id_to_section[row['id']] = row['section_number']
   except Exception as e: print("Error fetching courses:", e)

print(f"Loaded {len(id_to_section)} section mappings")

# 2. Fetch enrollments
req = urllib.request.Request(f"{url}/rest/v1/enrollments", headers=headers)
with urllib.request.urlopen(req) as res:
    enrollments = json.loads(res.read().decode())
    
    print(f"Found {len(enrollments)} total enrollments.")
    patched_count = 0
    for e in enrollments:
        sec_id = e.get('section_id')
        if sec_id and sec_id in id_to_section:
            sec_num = id_to_section[sec_id]
            
            patch_req = urllib.request.Request(
                f"{url}/rest/v1/enrollments?id=eq.{e['id']}",
                data=json.dumps({"section": str(sec_num)}).encode(),
                headers=headers,
                method="PATCH"
            )
            try:
                urllib.request.urlopen(patch_req)
                print(f"Patched {e['course_code']} -> Section {sec_num}")
                patched_count += 1
            except Exception as err:
                print(f"Failed to patch {e['id']}: {err}")
    print(f"Successfully updated 'section' column for {patched_count} enrollments.")

