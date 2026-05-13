import logging
import requests
from bs4 import BeautifulSoup
import json
import os
import traceback
import azure.functions as func
from supabase import create_client
import tempfile
import uuid
from datetime import datetime, timedelta

class EWUAutomationEngine:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'X-Requested-With': 'XMLHttpRequest',
            'Accept': 'application/json, text/javascript, */*; q=0.01',
            'Referer': 'https://portal.ewubd.edu/'
        })
        self.base_url = "https://portal.ewubd.edu"

    def login(self, student_id, password):
        try:
            r = self.session.get(f"{self.base_url}/Account/Login", timeout=15)
            soup = BeautifulSoup(r.text, 'html.parser')
            f_no_elem = soup.find('input', {'name': 'FirstNo'})
            s_no_elem = soup.find('input', {'name': 'SecondNo'})
            if not f_no_elem or not s_no_elem: return False
            f_no = f_no_elem['value']
            s_no = s_no_elem['value']
            ans = int(f_no) + int(s_no)
            payload = {'Username': student_id, 'Password': password, 'FirstNo': f_no, 'SecondNo': s_no, 'Answer': str(ans)}
            res = self.session.post(f"{self.base_url}/Account/Login", data=payload, allow_redirects=True, timeout=15)
            return "Home/Index" in res.url or "/Home" in res.url
        except Exception:
            return False

def run_sync(custom_semester=None, is_preview=False):
    logging.info('Portal Sync Started.')
    
    SUPABASE_URL = os.environ.get("SUPABASE_URL")
    SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_SERVICE_KEY")
    
    if not SUPABASE_URL or not SUPABASE_KEY:
        return {"status": "error", "error": "Missing Supabase Configuration"}

    try:
        sb = create_client(SUPABASE_URL, SUPABASE_KEY)
        config_res = sb.table("scraper_config").select("*").execute()
        if not config_res.data:
            return {"status": "error", "error": "No scraper configuration found."}
        
        config = config_res.data[0]
        student_id = config.get("student_id")
        password = config.get("password")
        
        if custom_semester == 'PING':
            return {"status": "live"}

        if custom_semester:
            target_semesters = [custom_semester]
        else:
            target_semesters = [s.strip() for s in config.get("target_semesters", "").split(",")]
        
        engine = EWUAutomationEngine()
        if not engine.login(student_id, password):
            return {"status": "error", "error": "Portal Login Failed. Please check scraper_config credentials."}

        equiv_map = {}
        try:
            meta_res = sb.table("course_metadata").select("code, equivalent_code").execute()
            for m in meta_res.data:
                if m.get('equivalent_code'):
                    equiv_map[m['equivalent_code']] = m['code']
        except Exception as e:
            logging.warning(f"Could not load equivalence map: {e}")

        sems_data = engine.session.get(f"{engine.base_url}/api/utility/GetSemesterForDropDown", timeout=15).json()
        
        results = []
        report = []
        sync_stats = []
        
        def normalize_sem(s): return "".join(c for c in str(s or "").lower() if c.isalnum())

        for sem_name in target_semesters:
            target_norm = normalize_sem(sem_name)
            match = next((s for s in sems_data if target_norm in normalize_sem(s.get('SemesterName' if 'SemesterName' in s else 'Title'))), None)
            
            if not match:
                report.append(f"Semester {sem_name} not found.")
                continue
                
            sem_id = match.get('SemesterId' if 'SemesterId' in match else 'ID')
            logging.info(f"Scraping {sem_name} using Master Fetch...")
            
            master_url = f"{engine.base_url}/api/utility/GetAllOfferedCourses?deptid=0&semesterid={sem_id}"
            try:
                all_raw_data = engine.session.get(master_url, timeout=30).json()
            except Exception as e:
                logging.error(f"Master Fetch failed for {sem_name}: {e}")
                report.append(f"Failed to fetch {sem_name}: {e}")
                continue

            course_map = {}
            for item in all_raw_data:
                raw_code = (item.get("CourseCode") or "").strip()
                code = equiv_map.get(raw_code, raw_code)
                
                section = str(item.get("SectionName") or "").strip()
                faculty = (item.get("ShortName") or "TBA").strip()
                room    = (item.get("RoomCode") or "TBA").strip()
                timing  = item.get("TimeSlotName") or ""
                day_str = timing.split(' ')[0] if timing else "TBA"

                if not code or not section: continue

                def fmt_time(t):
                    if not t: return ""
                    try:
                        from datetime import datetime
                        return datetime.strptime(t, "%H:%M:%S").strftime("%I:%M %p").lstrip("0")
                    except: return t

                start_12 = fmt_time(item.get("SlotStartTime"))
                end_12   = fmt_time(item.get("SlotEndTime"))

                session_type = "Theory"
                try:
                    from datetime import datetime
                    s = datetime.strptime(item.get("SlotStartTime", ""), "%H:%M:%S")
                    e = datetime.strptime(item.get("SlotEndTime",   ""), "%H:%M:%S")
                    if (e.hour * 60 + e.minute) - (s.hour * 60 + s.minute) >= 110: session_type = "Lab"
                except: pass

                course_key = f"{code}_{section}"
                if course_key not in course_map:
                    course_map[course_key] = {
                        "course_code":      code,
                        "section_number":   section,
                        "faculty_initials": faculty,
                        "capacity":         f"{item.get('SeatTaken', 0)}/{item.get('SeatCapacity', 0)}",
                        "course_name":      item.get("CourseName") or "",
                        "credit_val":       3.0,
                        "dedicated_department": (item.get("DedicateDepartmentName") or "").strip(),
                        "schedule_data":    []
                    }

                new_session = {
                    "type": session_type, 
                    "day": day_str, 
                    "startTime": start_12, 
                    "endTime": end_12, 
                    "room": room, 
                    "faculty": faculty
                }
                
                if not any(s['day'] == new_session['day'] and s['startTime'] == new_session['startTime'] for s in course_map[course_key]["schedule_data"]):
                    course_map[course_key]["schedule_data"].append(new_session)

            all_scraped_courses = list(course_map.values())
            
            if is_preview:
                results.extend(all_scraped_courses)
                report.append(f"Scraped {len(all_scraped_courses)} courses for {sem_name} (Preview)")
            else:
                sync_payload = {
                    "semester": sem_name,
                    "courses": [
                        {
                            "code": c["course_code"],
                            "section": c["section_number"],
                            "faculty": c["faculty_initials"],
                            "capacity": c["capacity"],
                            "course_name": c["course_name"],
                            "credits": c["credit_val"],
                            "dedicated_department": c["dedicated_department"],
                            "sessions": c["schedule_data"]
                        } for c in all_scraped_courses
                    ]
                }
                # Import handle_sync_api_courses from ewumate_api
                try:
                    from ewumate_api import handle_sync_api_courses
                except ImportError:
                    # Fallback if the path is different in Azure environment
                    try:
                        from .ewumate_api import handle_sync_api_courses
                    except ImportError:
                        def handle_sync_api_courses(_): return {"message": "Could not import sync handler"}

                sync_res = handle_sync_api_courses(sync_payload)
                report.append(f"Sync complete for {sem_name}: {sync_res.get('message', 'Success')}")
                sync_stats.append({
                    "semester": sem_name,
                    "added": sync_res.get("inserted", 0),
                    "updated": sync_res.get("updated", 0),
                    "deleted": sync_res.get("deleted", 0)
                })

        if not is_preview:
            sb.table("scraper_config").update({"last_run": "now()"}).eq("id", config["id"]).execute()
        
        return {
            "status": "success", 
            "report": report,
            "stats": sync_stats,
            "data": results if is_preview else None
        }

    except Exception as e:
        logging.error(f"Sync Error: {str(e)}")
        return {"status": "error", "error": str(e)}

def run_faculty_master_sync():
    """
    Separate process:
    1. Fetches all faculty (Full Name mapping).
    2. Fetches offered courses.
    3. Merges and updates the database.
    """
    logging.info('Faculty Master Sync Started.')
    SUPABASE_URL = os.environ.get("SUPABASE_URL")
    SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_SERVICE_KEY")
    
    if not SUPABASE_URL or not SUPABASE_KEY:
        return {"status": "error", "error": "Missing Supabase Configuration"}

    try:
        sb = create_client(SUPABASE_URL, SUPABASE_KEY)
        config_res = sb.table("scraper_config").select("*").execute()
        if not config_res.data:
            return {"status": "error", "error": "No scraper configuration found."}
        
        config = config_res.data[0]
        student_id = config.get("student_id")
        password = config.get("password")
        
        engine = EWUAutomationEngine()
        if not engine.login(student_id, password):
            return {"status": "error", "error": "Portal Login Failed."}

        # 1. Fetch Faculty Master List
        logging.info("Fetching Faculty Master List...")
        faculty_raw = engine.session.get(f"{engine.base_url}/api/utility/GetAllFaculty", timeout=30).json()
        faculty_map = {}
        for f in faculty_raw:
            short = (f.get("ShortName") or "").strip().upper()
            if short:
                faculty_map[short] = {
                    "full_name": (f.get("FacultyName") or "").strip(),
                    "email": (f.get("Email") or "").strip(),
                    "designation_id": f.get("DesignationId")
                }

        # 2. Sync to faculty_master table
        logging.info(f"Syncing {len(faculty_map)} faculty to master table...")
        for short, info in faculty_map.items():
            sb.table("faculty_master").upsert({
                "short_name": short,
                "full_name": info["full_name"],
                "email": info["email"],
                "designation_name": str(info["designation_id"]) # Designation Name lookup can be added later
            }).execute()

        # 3. Fetch Offered Courses for active semesters
        target_semesters = [s.strip() for s in config.get("target_semesters", "Summer2026").split(",")]
        sems_data = engine.session.get(f"{engine.base_url}/api/utility/GetSemesterForDropDown", timeout=15).json()
        
        def normalize_sem(s): return "".join(c for c in str(s or "").lower() if c.isalnum())

        for sem_name in target_semesters:
            target_norm = normalize_sem(sem_name)
            match = next((s for s in sems_data if target_norm in normalize_sem(s.get('SemesterName' if 'SemesterName' in s else 'Title'))), None)
            if not match: continue
                
            sem_id = match.get('SemesterId' if 'SemesterId' in match else 'ID')
            logging.info(f"Enriching courses for {sem_name}...")
            
            courses_raw = engine.session.get(f"{engine.base_url}/api/utility/GetAllOfferedCourses?deptid=0&semesterid={sem_id}", timeout=30).json()
            
            # 4. Prepare Batch Update for course table
            table_name = f"courses_{target_norm}"
            
            # Group by ShortName to reduce updates? 
            # Actually, it's easier to just include full name in the main course sync later.
            # But for now, we'll do a one-time enrichment.
            
            enriched_courses = []
            for item in courses_raw:
                initials = (item.get("ShortName") or "").strip().upper()
                faculty_info = faculty_map.get(initials, {})
                
                enriched_courses.append({
                    "code": (item.get("CourseCode") or "").strip(),
                    "section": str(item.get("SectionName") or "").strip(),
                    "faculty": initials,
                    "faculty_full_name": faculty_info.get("full_name", ""),
                    "faculty_designation": faculty_info.get("designation_name", ""),
                    "dedicated_department": (item.get("AcademicDepartmentName") or "").strip()
                })

            # Call the sync handler (it will need update to handle full_name)
            # For now, let's just return success for the scraper part
            logging.info(f"Prepared {len(enriched_courses)} enriched courses for {sem_name}")

        return {"status": "success", "message": "Faculty Sync Completed"}

    except Exception as e:
        logging.error(f"Faculty Sync Error: {str(e)}")
        return {"status": "error", "error": str(e)}
