import json
import requests

URL = "https://jwygjihrbwxhehijldiz.supabase.co/rest/v1/programs"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"
HEADERS = {
    'apikey': KEY,
    'Authorization': f'Bearer {KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'resolution=merge-duplicates' # Handles upsert automatically based on primary key
}

# 1. Fetch existing programs from DB
print("Fetching existing programs from Supabase...")
res = requests.get(f"{URL}?select=*", headers=HEADERS)
db_programs = res.json()
print(f"Found {len(db_programs)} existing programs.")

prog_map = { p['program_code']: p for p in db_programs }

# 2. Read new programs from our JSON file
with open('new_programs_from_image.json', 'r') as f:
    new_progs = json.load(f)

# 3. Read graduate_programs.json to copy exact department names where available
with open('graduate_programs.json', 'r') as f:
    grad_progs = json.load(f)
grad_dept_map = { p['program_code']: p['department_name'] for p in grad_progs }
grad_track_map = { p['program_code']: p.get('track', 'tri_semester') for p in grad_progs }

print(f"Merging {len(new_progs)} new program entries...")

for np in new_progs:
    code = np['program_code']
    
    # Use exact department name if we have it in graduate_programs, otherwise fall back to faculty from image
    dept_name = grad_dept_map.get(code)
    if not dept_name:
        # Try finding a root program code match (e.g. for MA_ENG_40)
        base_code = code.split('_')[0] + ('_' + code.split('_')[1] if len(code.split('_'))>1 else '')
        dept_name = grad_dept_map.get(base_code, np.get('faculty', 'Unknown'))
        
    track = grad_track_map.get(code)
    if not track:
        base_code = code.split('_')[0] + ('_' + code.split('_')[1] if len(code.split('_'))>1 else '')
        track = grad_track_map.get(base_code, 'tri_semester')
        if 'LLM' in code or 'PHARM' in code:
            track = 'bi_semester'

    merged = prog_map.get(code, {})
    merged['program_code'] = code
    merged['name'] = np['name']
    merged['department_name'] = dept_name
    merged['total_degree_credits'] = np['total_degree_credits']
    merged['track'] = track
    
    prog_map[code] = merged

final_programs = list(prog_map.values())

# 4. Save merged final database table state back to JSON
with open('all_programs_merged.json', 'w') as f:
    json.dump(final_programs, f, indent=4)
print("Saved final merged snapshot to 'all_programs_merged.json'")

# 5. Upsert to Supabase
print("Uploading to Supabase...")
push_res = requests.post(URL, headers=HEADERS, json=final_programs)

if push_res.status_code in [200, 201, 204]:
    print("SUCCESS: All programs uploaded and merged with the database successfully!")
else:
    print(f"FAILED: {push_res.status_code} - {push_res.text}")
