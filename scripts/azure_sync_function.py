import logging
import azure.functions as func
import os
import json
from datetime import datetime
import requests
from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor
from supabase import create_client, Client

# --- SETUP ---
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

class EWUAzureWorker:
    def __init__(self, student_id, password):
        self.student_id = student_id
        self.password = password
        self.session = requests.Session()
        self.session.headers.update({'X-Requested-With': 'XMLHttpRequest'})

    def login(self):
        try:
            r = self.session.get("https://portal.ewubd.edu/Account/Login", timeout=15)
            soup = BeautifulSoup(r.text, 'html.parser')
            f_no = soup.find('input', {'name': 'FirstNo'})['value']
            s_no = soup.find('input', {'name': 'SecondNo'})['value']
            payload = {'Username': self.student_id, 'Password': self.password, 'FirstNo': f_no, 'SecondNo': s_no, 'Answer': str(int(f_no)+int(s_no))}
            res = self.session.post("https://portal.ewubd.edu/Account/Login", data=payload, timeout=15)
            return "Home/Index" in res.url or "/Home" in res.url
        except: return False

    def sync_semester(self, sem_name):
        # 1. Scrape (Fast Engine)
        sems = self.session.get("https://portal.ewubd.edu/api/utility/GetSemesterForDropDown").json()
        target = next((s for s in sems if sem_name.lower() in str(s).lower()), None)
        if not target: return f"Semester {sem_name} not found"
        
        sem_id = target.get('SemesterId') or target.get('ID')
        depts = self.session.get("https://portal.ewubd.edu/api/utility/GetAllAcademicDepartments").json()
        
        all_records = []
        def fetch(d_id): 
            try: return self.session.get(f"https://portal.ewubd.edu/api/utility/GetAllOfferedCourses?deptid={d_id}&semesterid={sem_id}").json()
            except: return []

        with ThreadPoolExecutor(max_workers=10) as exe:
            results = exe.map(fetch, [d.get('AcademicDepartmentId') for d in depts])
            for r in results: all_records.extend(r)

        # 2. Transform
        course_map = {}
        for item in all_records:
            code, sec = (item.get("CourseCode") or "").strip(), str(item.get("SectionName") or "").strip()
            if not code or not sec: continue
            key = f"{code}_{sec}"
            if key not in course_map:
                course_map[key] = {
                    "course_code": code, "section_number": sec, 
                    "faculty_initials": (item.get("ShortName") or "TBA").strip(),
                    "dedicated_department": (item.get("DedicateDepartmentName") or "").strip(),
                    "capacity": f"{item.get('SeatTaken', 0)}/{item.get('SeatCapacity', 0)}",
                    "course_name": item.get("CourseName") or "", "schedule_data": []
                }
            course_map[key]["schedule_data"].append({
                "day": item.get("TimeSlotName", "").split(' ')[0],
                "startTime": item.get("SlotStartTime"), "endTime": item.get("SlotEndTime"),
                "room": (item.get("RoomCode") or "TBA").strip(), "type": "Theory"
            })

        # 3. Upsert
        tbl = f"courses_{sem_name.lower().replace('-', '').replace(' ', '')}"
        supabase.table(tbl).upsert(list(course_map.values()), on_conflict="course_code,section_number").execute()
        return f"Synced {len(course_map)} courses to {tbl}"

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Triggering Nightly Portal Sync...')
    
    # Fetch Config from Supabase
    config = supabase.table("scraper_config").select("*").limit(1).execute().data[0]
    semesters = [s.strip() for s in config['target_semesters'].split(',')]
    
    worker = EWUAzureWorker(config['student_id'], config['password'])
    if not worker.login():
        return func.HttpResponse("Portal Login Failed", status_code=401)

    reports = []
    for sem in semesters:
        status = worker.sync_semester(sem)
        reports.append(status)
    
    # Update Last Run
    supabase.table("scraper_config").update({"last_run": "now()"}).eq("id", config['id']).execute()

    return func.HttpResponse("\n".join(reports), status_code=200)
