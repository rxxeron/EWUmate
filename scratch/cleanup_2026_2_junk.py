import requests

SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co"
SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY"

def cleanup_junk():
    headers = {
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "apikey": SUPABASE_KEY,
    }
    
    # 1. Get all user_ids for student_id starting with 2026-2
    profiles = requests.get(f"{SUPABASE_URL}/rest/v1/profiles?student_id=like.2026-2*&select=id", headers=headers).json()
    user_ids = [p['id'] for p in profiles]
    
    print(f"Found {len(user_ids)} users with intake 2026-2.")
    
    # 2. Delete Spring 2026 enrollments for these users
    # We'll do this in chunks of 50 to avoid long URLs
    for i in range(0, len(user_ids), 50):
        chunk = user_ids[i:i+50]
        ids_str = ",".join(chunk)
        url = f"{SUPABASE_URL}/rest/v1/enrollments?semester_code=eq.Spring2026&user_id=in.({ids_str})"
        res = requests.delete(url, headers=headers)
        print(f"Chunk {i//50 + 1}: Status {res.status_code}")

if __name__ == "__main__":
    cleanup_junk()
