import json
import requests

json_path = r"d:\EWUmate\EWUmate_Clean\ewumate_v2\cse_masters.json"

with open(json_path, "r", encoding="utf-8") as f:
    courses = json.load(f)

# Extract the old 9xxx codes we previously saved as 'equivalent_code'
old_codes = [c["equivalent_code"] for c in courses if c.get("equivalent_code")]

print(f"Found {len(old_codes)} old 9xxx codes to delete from the database.")

if not old_codes:
    print("No old codes to delete.")
    exit(0)

URL = "https://jwygjihrbwxhehijldiz.supabase.co/rest/v1/course_metadata"
KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY"
HEADERS = {
    "apikey": KEY,
    "Authorization": f"Bearer {KEY}"
}

# Supabase REST API allows bulk delete using the `in` filter
# e.g., DELETE /course_metadata?code=in.(ACT9521,ENT9521,...)

chunk_size = 50
success_count = 0
for i in range(0, len(old_codes), chunk_size):
    chunk = old_codes[i : i + chunk_size]
    # Join chunk with commas
    code_list = ",".join(chunk)
    
    delete_url = f"{URL}?code=in.({code_list})"
    res = requests.delete(delete_url, headers=HEADERS)
    
    if res.status_code in [200, 204]:
        print(f"Chunk {i // chunk_size + 1} deleted successfully!")
        success_count += len(chunk)
    else:
        print(f"FAILED on chunk {i // chunk_size + 1}: {res.status_code} - {res.text}")

print(f"Cleaned up {success_count} legacy 9xxx courses from `course_metadata`.")
