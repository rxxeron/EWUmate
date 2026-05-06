import requests

SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co"
SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY"

def find_conflicts():
    headers = {
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "apikey": SUPABASE_KEY,
    }
    
    # 1. Get all upcoming for Summer 2026
    upcoming = requests.get(f"{SUPABASE_URL}/rest/v1/enrollments?semester_code=eq.Summer2026&status=eq.upcoming", headers=headers).json()
    
    # 2. Get all enrolled (any semester)
    enrolled = requests.get(f"{SUPABASE_URL}/rest/v1/enrollments?status=eq.enrolled", headers=headers).json()
    
    enrolled_set = set([(e['user_id'], e['course_code']) for e in enrolled])
    
    conflicts = []
    for u in upcoming:
        if (u['user_id'], u['course_code']) in enrolled_set:
            conflicts.append(u)
            
    print(f"Total Conflicts: {len(conflicts)}")
    for c in conflicts[:10]:
        print(f"User: {c['user_id']} | Course: {c['course_code']} | ID: {c['id']}")

if __name__ == "__main__":
    find_conflicts()
