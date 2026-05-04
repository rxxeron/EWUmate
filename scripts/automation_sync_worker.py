import os
import time
import json
from datetime import datetime
import requests
from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor
# Note: You will need to install 'supabase' and 'requests' and 'beautifulsoup4'
# pip install supabase requests beautifulsoup4

try:
    from supabase import create_client, Client
except ImportError:
    print("[ERROR] Please install supabase: pip install supabase")
    exit(1)

# --- CONFIGURATION (Set these in your Environment or .env) ---
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://your-project.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY") # CRITICAL: Use Service Role Key
PORTAL_USER = os.getenv("PORTAL_STUDENT_ID")
PORTAL_PASS = os.getenv("PORTAL_PASSWORD")

if not SUPABASE_KEY or not PORTAL_USER or not PORTAL_PASS:
    print("[ERROR] Missing environment variables. Need SUPABASE_SERVICE_ROLE_KEY, PORTAL_STUDENT_ID, and PORTAL_PASSWORD.")
    exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

class EWUAutomationWorker:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'X-Requested-With': 'XMLHttpRequest'
        })

    def login(self):
        print(f"[{datetime.now()}] [LOGIN] Logging into portal as {PORTAL_USER}...")
        try:
            r = self.session.get("https://portal.ewubd.edu/Account/Login", timeout=20)
            soup = BeautifulSoup(r.text, 'html.parser')
            f_no_elem = soup.find('input', {'name': 'FirstNo'})
            s_no_elem = soup.find('input', {'name': 'SecondNo'})
            if not f_no_elem or not s_no_elem: return False
            
            f_no = f_no_elem['value']
            s_no = s_no_elem['value']
            ans = int(f_no) + int(s_no)
            
            payload = {
                'Username': PORTAL_USER,
                'Password': PORTAL_PASS,
                'FirstNo': f_no,
                'SecondNo': s_no,
                'Answer': str(ans)
            }
            res = self.session.post("https://portal.ewubd.edu/Account/Login", data=payload, allow_redirects=True, timeout=20)
            return "Home/Index" in res.url or "/Home" in res.url
        except Exception as e:
            print(f"[ERROR] Login failed: {e}")
            return False

    def fetch_dept_data(self, dept_id, sem_id):
        url = f"https://portal.ewubd.edu/api/utility/GetAllOfferedCourses?deptid={dept_id}&semesterid={sem_id}"
        try:
            return self.session.get(url, timeout=20).json()
        except:
            return []

    def sync_semester(self, semester_name):
        print(f"[{datetime.now()}] [SYNC] Starting sync for {semester_name}...")
        
        # 1. Get Semester ID
        try:
            sems = self.session.get("https://portal.ewubd.edu/api/utility/GetSemesterForDropDown").json()
            target = next((s for s in sems if semester_name.lower() in s.get('SemesterName', '').lower() or semester_name.lower() in s.get('Title', '').lower()), None)
            if not target:
                print(f"[SKIP] Semester {semester_name} not found in portal.")
                return
            
            sem_id = target.get('SemesterId') or target.get('ID')
        except:
            print("[ERROR] Could not fetch semester list.")
            return
        
        # 2. Get All Departments
        try:
            depts = self.session.get("https://portal.ewubd.edu/api/utility/GetAllAcademicDepartments").json()
        except:
            print("[ERROR] Could not fetch department list.")
            return
        
        # 3. Parallel Scrape
        all_portal_records = []
        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(self.fetch_dept_data, d.get('AcademicDepartmentId'), sem_id) for d in depts]
            for f in futures:
                all_portal_records.extend(f.result())
        
        # 4. Group by Course_Section
        course_map = {}
        for item in all_portal_records:
            code = (item.get("CourseCode") or "").strip()
            sec = str(item.get("SectionName") or "").strip()
            if not code or not sec: continue
            
            key = f"{code}_{sec}"
            if key not in course_map:
                course_map[key] = {
                    "course_code": code,
                    "section_number": sec,
                    "faculty_initials": (item.get("ShortName") or "TBA").strip(),
                    "dedicated_department": (item.get("DedicateDepartmentName") or "").strip(),
                    "capacity": f"{item.get('SeatTaken', 0)}/{item.get('SeatCapacity', 0)}",
                    "course_name": item.get("CourseName") or "",
                    "schedule_data": []
                }
            
            def to_12h(t):
                if not t: return ""
                try:
                    from datetime import datetime
                    return datetime.strptime(t, "%H:%M:%S").strftime("%I:%M %p").lstrip("0")
                except: return t

            course_map[key]["schedule_data"].append({
                "day": item.get("TimeSlotName", "").split(' ')[0],
                "startTime": to_12h(item.get("SlotStartTime")),
                "endTime": to_12h(item.get("SlotEndTime")),
                "room": (item.get("RoomCode") or "TBA").strip(),
                "type": "Theory" # Add logic for Lab if needed
            })

        # 5. Push to Supabase
        # Normalize semester name for table name (e.g. Summer-2026 -> courses_summer2026)
        clean_sem = semester_name.lower().replace('-', '').replace(' ', '')
        table_name = f"courses_{clean_sem}"
        data_to_upsert = list(course_map.values())
        
        print(f"[DB] Upserting {len(data_to_upsert)} records into {table_name}...")
        try:
            # Note: Ensure (course_code, section_number) has a UNIQUE constraint in your DB
            supabase.table(table_name).upsert(
                data_to_upsert, 
                on_conflict="course_code,section_number"
            ).execute()
            print(f"[{datetime.now()}] [SUCCESS] Sync completed for {semester_name}")
        except Exception as e:
            print(f"[ERROR] Supabase push failed: {e}")

if __name__ == "__main__":
    worker = EWUAutomationWorker()
    if worker.login():
        # Add target semesters here
        for sem in ["Summer-2025"]:
            worker.sync_semester(sem)
    else:
        print("[CRITICAL] Could not start sync: Login failed.")
