import requests
from bs4 import BeautifulSoup
import json
import time
from concurrent.futures import ThreadPoolExecutor
from http.server import BaseHTTPRequestHandler, HTTPServer
import threading

class EWUScraper:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'X-Requested-With': 'XMLHttpRequest',
            'Accept': 'application/json, text/javascript, */*; q=0.01',
            'Referer': 'https://portal.ewubd.edu/'
        })

    def login(self, student_id, password):
        print(f"[LOGIN] Authenticating {student_id}...")
        try:
            r = self.session.get("https://portal.ewubd.edu/Account/Login", timeout=15)
            soup = BeautifulSoup(r.text, 'html.parser')
            f_no_elem = soup.find('input', {'name': 'FirstNo'})
            s_no_elem = soup.find('input', {'name': 'SecondNo'})
            if not f_no_elem or not s_no_elem: return False
            f_no = f_no_elem['value']
            s_no = s_no_elem['value']
            ans = int(f_no) + int(s_no)
            payload = {'Username': student_id, 'Password': password, 'FirstNo': f_no, 'SecondNo': s_no, 'Answer': str(ans)}
            res = self.session.post("https://portal.ewubd.edu/Account/Login", data=payload, allow_redirects=True, timeout=15)
            return "Home/Index" in res.url or "/Home" in res.url
        except: return False

    def fetch_dept(self, dept_id, sem_id, dept_name="Unknown", semester_name=""):
        url = f"https://portal.ewubd.edu/api/utility/GetAllOfferedCourses?deptid={dept_id}&semesterid={sem_id}"
        course_map = {}
        try:
            data = self.session.get(url, timeout=15).json()
            for item in data:
                code    = (item.get("CourseCode") or "").strip()
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
                is_mba_emba = (any(x in str(dept_name).upper() for x in ["MBA", "EMBA"]) or any(str(code).upper().startswith(x) for x in ["MBA", "EMBA"]))
                if not is_mba_emba:
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
                        "original_code":    code,
                        "section_number":   section,
                        "faculty_initials": faculty,
                        "dedicated_department": (item.get("DedicateDepartmentName") or "").strip(),
                        "capacity":         f"{item.get('SeatTaken', 0)}/{item.get('SeatCapacity', 0)}",
                        "course_name":      item.get("CourseName") or "",
                        "credit_val":       3.0,
                        "schedule_data":    []
                    }

                course_map[course_key]["schedule_data"].append({"type": session_type, "day": day_str, "startTime": start_12, "endTime": end_12, "room": room, "faculty": faculty})
                if course_map[course_key]["faculty_initials"] == "TBA" and faculty != "TBA": course_map[course_key]["faculty_initials"] = faculty

            return list(course_map.values())
        except: return []

    def scrape_all(self, semester_name="Summer-2026"):
        start_time = time.time()
        def normalize(s): return "".join(c for c in str(s or "").lower() if c.isalnum())
        try:
            sems = self.session.get("https://portal.ewubd.edu/api/utility/GetSemesterForDropDown", timeout=15).json()
            target_norm = normalize(semester_name)
            target = next((s for s in sems if target_norm in normalize(s.get('SemesterName' if 'SemesterName' in s else 'Title'))), sems[0])
            sem_id = target.get('SemesterId' if 'SemesterId' in target else 'ID')
            depts = self.session.get("https://portal.ewubd.edu/api/utility/GetAllAcademicDepartments", timeout=15).json()
            all_data = []
            with ThreadPoolExecutor(max_workers=10) as executor:
                futures = [executor.submit(self.fetch_dept, d.get('AcademicDepartmentId'), sem_id, d.get('AcademicDepartmentName'), semester_name) for d in depts]
                for f in futures: all_data.extend(f.result())
            print(f"[COMPLETED] Captured {len(all_data)} records in {time.time() - start_time:.2f}s")
            return all_data
        except: return []

class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args): return
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
    def do_POST(self):
        if self.path == '/scrape':
            length = int(self.headers['Content-Length'])
            data = json.loads(self.rfile.read(length))
            print(f"\n[NETWORK] Received minimal scrape request for {data.get('semester')}...")
            scraper = EWUScraper()
            if scraper.login(data['id'], data['password']):
                results = scraper.scrape_all(data['semester'])
                response = {"status": "success", "data": results}
            else: response = {"status": "error", "message": "Portal Login Failed"}
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())

def run_server():
    print("\n" + "="*50)
    print("  EWUmate MINIMAL API ENGINE v7.0")
    print("  Listening on: http://localhost:5000")
    print("="*50 + "\n")
    httpd = HTTPServer(('0.0.0.0', 5000), SimpleHTTPRequestHandler)
    httpd.serve_forever()

if __name__ == '__main__':
    run_server()
