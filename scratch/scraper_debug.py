import requests
import json
from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor

class ScraperDebugger:
    def __init__(self, student_id, password):
        self.student_id = student_id
        self.password = password
        self.session = requests.Session()
        self.session.headers.update({'X-Requested-With': 'XMLHttpRequest', 'User-Agent': 'Mozilla/5.0'})

    def login(self):
        try:
            r = self.session.get("https://portal.ewubd.edu/Account/Login", timeout=15)
            soup = BeautifulSoup(r.text, 'html.parser')
            f_no = soup.find('input', {'name': 'FirstNo'})['value']
            s_no = soup.find('input', {'name': 'SecondNo'})['value']
            payload = {'Username': self.student_id, 'Password': self.password, 'FirstNo': f_no, 'SecondNo': s_no, 'Answer': str(int(f_no)+int(s_no))}
            res = self.session.post("https://portal.ewubd.edu/Account/Login", data=payload, timeout=15)
            return "Home/Index" in res.url or "/Home" in res.url
        except Exception as e: 
            print(f"Login failed: {e}")
            return False

    def debug_counts(self, sem_name):
        # 1. Get Semester ID
        sems = self.session.get("https://portal.ewubd.edu/api/utility/GetSemesterForDropDown").json()
        # Handle both Summer 2026 and Summer-2026
        normalized_target = sem_name.lower().replace(' ', '-').replace('_', '-')
        target = next((s for s in sems if normalized_target in str(s).lower().replace(' ', '-')), None)
        
        if not target: 
            print(f"Semester {sem_name} not found in {sems}")
            return
        
        sem_id = target.get('SemesterId') or target.get('ID')
        print(f"Targeting Semester ID: {sem_id} ({target.get('SemesterName')})")

        # 2. Method A: By Department (Current Scraper Logic)
        depts = self.session.get("https://portal.ewubd.edu/api/utility/GetAllAcademicDepartments").json()
        print(f"Found {len(depts)} Departments")
        
        all_records_dept = []
        def fetch_dept(d_id): 
            try: return self.session.get(f"https://portal.ewubd.edu/api/utility/GetAllOfferedCourses?deptid={d_id}&semesterid={sem_id}").json()
            except: return []

        with ThreadPoolExecutor(max_workers=10) as exe:
            results = exe.map(fetch_dept, [d.get('AcademicDepartmentId') for d in depts])
            for r in results: all_records_dept.extend(r)
        
        course_map_dept = {}
        for item in all_records_dept:
            code, sec = (item.get("CourseCode") or "").strip(), str(item.get("SectionName") or "").strip()
            if not code or not sec: continue
            course_map_dept[f"{code}_{sec}"] = item

        print(f"Method A (Dept) found: {len(course_map_dept)} unique sections")

        # 3. Method B: By Program
        programs = self.session.get("https://portal.ewubd.edu/api/utility/GetAllAcademicPrograms").json()
        print(f"Found {len(programs)} Programs")

        all_records_prog = []
        def fetch_prog(p_id): 
            try: return self.session.get(f"https://portal.ewubd.edu/api/utility/GetAllOfferedCoursesByProgram?programid={p_id}&semesterid={sem_id}").json()
            except: return []

        with ThreadPoolExecutor(max_workers=10) as exe:
            results = exe.map(fetch_prog, [p.get('AcademicProgramId') for p in programs])
            for r in results: all_records_prog.extend(r)

        course_map_prog = {}
        for item in all_records_prog:
            code, sec = (item.get("CourseCode") or "").strip(), str(item.get("SectionName") or "").strip()
            if not code or not sec: continue
            course_map_prog[f"{code}_{sec}"] = item

        print(f"Method B (Prog) found: {len(course_map_prog)} unique sections")

        # 4. Total Sections
        all_keys = set(course_map_dept.keys()) | set(course_map_prog.keys())
        print(f"Total unique sections across both methods: {len(all_keys)}")
        
        if len(all_keys) > len(course_map_dept):
            print(f"IMPROVEMENT: Using both methods gives {len(all_keys) - len(course_map_dept)} more sections.")

debugger = ScraperDebugger("2025-2-50-009", "rHrakib12@#")
if debugger.login():
    debugger.debug_counts("Summer 2026")
