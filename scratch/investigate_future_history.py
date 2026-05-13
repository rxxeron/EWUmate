
import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
dotenv_path = 'd:/EWUmate/EWUmate_Clean/ewumate_v2/ewumate_production_build/.env'
load_dotenv(dotenv_path)

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

print(f"--- Investigating Future Course History Entries ---")

# 1. Fetch entries from completed_courses for Summer2026 and Fall2026
res = supabase.table("completed_courses").select("user_id, course_code, semester_code, grade").in_("semester_code", ["Summer2026", "Fall2026"]).execute()

if res.data:
    for r in res.data:
        uid = r['user_id']
        code = r['course_code']
        sem = r['semester_code']
        grade = r['grade']
        
        # 2. Check if enrollment exists for this course/semester
        enr = supabase.table("enrollments").select("status").eq("user_id", uid).eq("course_code", code).eq("semester_code", sem).execute()
        en_status = enr.data[0]['status'] if enr.data else "No Enrollment"
        
        # 3. Get User Nickname
        prof = supabase.table("profiles").select("nickname").eq("id", uid).execute()
        name = prof.data[0].get('nickname') if prof.data else "Unknown"
        
        print(f"User: {name} ({uid[:8]}) | Sem: {sem} | Course: {code} | Grade: {grade} | Enrollment: {en_status}")
else:
    print("No future course history entries found.")
