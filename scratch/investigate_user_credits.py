
import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
dotenv_path = 'd:/EWUmate/EWUmate_Clean/ewumate_v2/ewumate_production_build/.env'
load_dotenv(dotenv_path)

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

user_id = "a9d6f7fc-e6d9-419c-9b6c-12815e7db7c5"

print(f"--- Investigating User: {user_id} ---")

# 0. Check Active Semester
active = supabase.table("active_semester").select("*").limit(1).single().execute()
current_sem = "Unknown"
if active.data:
    current_sem = active.data.get('current_semester_code')
    print(f"Current Active Semester: {current_sem}")
    print(f"Next Active Semester: {active.data.get('next_semester_code')}")

# 1. Check Profile
profile = supabase.table("profiles").select("*").eq("id", user_id).single().execute()
if profile.data:
    print(f"\nProfile found: {profile.data.get('full_name')} ({profile.data.get('nickname')})")
    print(f"Enrolled Credits in Profile: {profile.data.get('enrolled_credits')}")
    print(f"Enrolled Credits Next in Profile: {profile.data.get('enrolled_credits_next')}")
else:
    print("Profile not found!")

# 2. Check Enrollments
enrollments = supabase.table("enrollments").select("*").eq("user_id", user_id).execute()

print(f"\nEnrollments found: {len(enrollments.data)}")
total_curr_credits = 0
total_next_credits = 0

for en in enrollments.data:
    course_code = en.get('course_code')
    status = en.get('status')
    semester = en.get('semester_code')
    
    # Check course_metadata (using 'code' and 'credit_val')
    meta = supabase.table("course_metadata").select("credit_val").eq("code", course_code).execute()
    credits = 0
    if meta.data:
        credits = meta.data[0].get('credit_val', 0)
    else:
        # Check specific courses tables if not in metadata
        for table in ["courses_summer2026", "courses_spring2026"]:
            meta_s = supabase.table(table).select("credit_val").eq("course_code", course_code).execute()
            if meta_s.data:
                credits = meta_s.data[0].get('credit_val', 0)
                break
            
    print(f" - Course: {course_code} | Sem: {semester} | Status: {status} | Credits: {credits}")
    
    if status == 'enrolled':
        if semester == current_sem:
            total_curr_credits += credits
        else:
            total_next_credits += credits

print(f"\nCalculated Current Credits (for {current_sem}): {total_curr_credits}")
print(f"Calculated Next Credits: {total_next_credits}")
