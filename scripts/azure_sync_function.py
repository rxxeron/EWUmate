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
        # 1. Get Semester ID
        sems = self.session.get("https://portal.ewubd.edu/api/utility/GetSemesterForDropDown").json()
        normalized_target = sem_name.lower().replace(' ', '-').replace('_', '-')
        target = next((s for s in sems if normalized_target in str(s).lower().replace(' ', '-')), None)
        
        if not target: 
            logging.error(f"Semester {sem_name} not found in portal dropdown.")
            return f"Semester {sem_name} not found"
        
        sem_id = target.get('SemesterId') or target.get('ID')
        logging.info(f"Syncing All Courses for: {sem_name} (ID: {sem_id})")

        # 2. Master Fetch: Use deptid=0 to get the complete university offering in one call
        url = f"https://portal.ewubd.edu/api/utility/GetAllOfferedCourses?deptid=0&semesterid={sem_id}"
        try:
            all_records = self.session.get(url, timeout=30).json()
        except Exception as e:
            logging.error(f"Failed to fetch master list for {sem_name}: {e}")
            return f"Fetch failed: {str(e)}"

        if not all_records:
            return f"Zero records returned for {sem_name}"

        # 3. Transform & Deduplicate
        course_map = {}
        for item in all_records:
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
            
            # Extract and add unique schedule slots
            slot_name = item.get("TimeSlotName") or ""
            day = slot_name.split(' ')[0] if slot_name else "TBA"
            
            new_slot = {
                "day": day,
                "startTime": item.get("SlotStartTime"), 
                "endTime": item.get("SlotEndTime"),
                "room": (item.get("RoomCode") or "TBA").strip(), 
                "type": "Theory"
            }
            
            # Only add if slot is unique for this section
            if not any(s['day'] == new_slot['day'] and s['startTime'] == new_slot['startTime'] for s in course_map[key]["schedule_data"]):
                course_map[key]["schedule_data"].append(new_slot)

        # 4. Batch Upsert to Supabase
        tbl = f"courses_{sem_name.lower().replace('-', '').replace(' ', '')}"
        
        try:
            supabase.table(tbl).upsert(list(course_map.values()), on_conflict="course_code,section_number").execute()
            return f"Success: Synced {len(course_map)} unique sections to {tbl}"
        except Exception as e:
            logging.error(f"Database upsert failed for {tbl}: {e}")
            return f"Failed to sync {sem_name}: {str(e)}"

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
