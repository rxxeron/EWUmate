import urllib.request
import json
import time

# Supabase Credentials
URL = "https://jwygjihrbwxhehijldiz.supabase.co"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"

def retrigger_all():
    print("--- GPA & Credit Refresh Tool ---")
    
    # 1. Fetch all user IDs from profiles
    print("Fetching student list...")
    req = urllib.request.Request(
        f"{URL}/rest/v1/profiles?select=id",
        headers={"apikey": KEY, "Authorization": f"Bearer {KEY}"}
    )
    
    try:
        with urllib.request.urlopen(req) as response:
            users = json.loads(response.read().decode())
    except Exception as e:
        print(f"Error fetching users: {e}")
        return

    total = len(users)
    print(f"Found {total} students. Starting recalculation...")

    # 2. Trigger sync-academic-stats for each user
    success_count = 0
    for i, user in enumerate(users):
        uid = user['id']
        sync_url = f"{URL}/functions/v1/sync-academic-stats"
        data = json.dumps({"user_id": uid}).encode()
        
        sync_req = urllib.request.Request(
            sync_url,
            data=data,
            headers={
                "apikey": KEY,
                "Authorization": f"Bearer {KEY}",
                "Content-Type": "application/json"
            },
            method="POST"
        )
        
        try:
            with urllib.request.urlopen(sync_req, timeout=30) as resp:
                # print(f"[{i+1}/{total}] Synced Student {uid}")
                success_count += 1
        except Exception as e:
            print(f"[{i+1}/{total}] FAILED Student {uid}: {e}")
        
        # Polite delay to avoid hammering the Edge Function
        if i % 10 == 0 and i > 0:
            print(f"Progress: {i}/{total} students processed...")
            time.sleep(1)

    print(f"\n--- Recalculation Complete ---")
    print(f"Successfully refreshed {success_count} out of {total} student profiles.")

if __name__ == "__main__":
    retrigger_all()
