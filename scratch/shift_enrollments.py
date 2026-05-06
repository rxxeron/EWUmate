import requests
import json

SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co"
SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY"

def shift_enrollments():
    headers = {
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "apikey": SUPABASE_KEY,
        "Content-Type": "application/json",
        "Prefer": "return=minimal"
    }
    
    url = f"{SUPABASE_URL}/rest/v1/enrollments?semester_code=eq.Summer2026&status=eq.upcoming"
    payload = {"status": "enrolled"}
    
    response = requests.patch(url, headers=headers, json=payload)
    print(f"Status: {response.status_code}")
    print(f"Body: {response.text}")

if __name__ == "__main__":
    shift_enrollments()
