import json
import requests

URL = "https://jwygjihrbwxhehijldiz.supabase.co/rest/v1/course_metadata"
KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY"
HEADERS = {
    "apikey": KEY,
    "Authorization": f"Bearer {KEY}",
    "Content-Type": "application/json",
    "Prefer": "resolution=merge-duplicates"
}

with open("d:\\EWUmate\\EWUmate_Clean\\ewumate_v2\\cse_masters.json", "r", encoding="utf-8") as f:
    courses_raw = json.load(f)

mapped_courses = []
for c in courses_raw:
    mapped_courses.append({
        "code": c["course_code"],
        "name": c["course_name"],
        "credit_val": c["credits"]
    })

print(f"Uploading {len(mapped_courses)} mapped courses to `course_metadata`...")

chunk_size = 100
for i in range(0, len(mapped_courses), chunk_size):
    chunk = mapped_courses[i : i + chunk_size]
    res = requests.post(URL, headers=HEADERS, json=chunk)
    
    if res.status_code in [200, 201, 204]:
        print(f"Chunk {i // chunk_size + 1} uploaded successfully!")
    else:
        print(f"FAILED on chunk {i // chunk_size + 1}: {res.status_code} - {res.text}")

