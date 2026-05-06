import sys
import os
import requests
from bs4 import BeautifulSoup
import json

class ScraperTester:
    def __init__(self, student_id, password):
        self.student_id = student_id
        self.password = password
        self.session = requests.Session()
        self.session.headers.update({
            'X-Requested-With': 'XMLHttpRequest',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        })

    def login(self):
        try:
            r = self.session.get("https://portal.ewubd.edu/Account/Login", timeout=15)
            soup = BeautifulSoup(r.text, 'html.parser')
            f_no = soup.find('input', {'name': 'FirstNo'})['value']
            s_no = soup.find('input', {'name': 'SecondNo'})['value']
            payload = {
                'Username': self.student_id, 
                'Password': self.password, 
                'FirstNo': f_no, 
                'SecondNo': s_no, 
                'Answer': str(int(f_no)+int(s_no))
            }
            res = self.session.post("https://portal.ewubd.edu/Account/Login", data=payload, timeout=15)
            print(f"Login Response URL: {res.url}")
            print(f"Login Response Status: {res.status_code}")
            return "Home/Index" in res.url or "/Home" in res.url
        except Exception as e:
            print(f"Login Error: {e}")
            return False

    def test_sync(self, sem_name):
        print(f"Testing Scraper for: {sem_name}")
        api_headers = {
            'Referer': 'https://portal.ewubd.edu/Home/OfferedCoursesStudent',
            'X-Requested-With': 'XMLHttpRequest'
        }
        sems_res = self.session.get("https://portal.ewubd.edu/api/utility/GetSemesterForDropDown", headers=api_headers)
        sems = sems_res.json()
        print(f"Available Semesters from API: {json.dumps(sems, indent=2)}")
        normalized_target = sem_name.lower().replace(' ', '-').replace('_', '-')
        target = next((s for s in sems if normalized_target in str(s).lower().replace(' ', '-')), None)
        
        if not target: 
            print(f"Error: Semester {sem_name} not found")
            return
        
        sem_id = target.get('SemesterId') or target.get('ID')
        print(f"Semester ID Found: {sem_id}")

        url = f"https://portal.ewubd.edu/api/utility/GetAllOfferedCourses?deptid=0&semesterid={sem_id}"
        print(f"Fetching from: {url}")
        res = self.session.get(url, headers=api_headers, timeout=30)
        print(f"Response Status: {res.status_code}")
        print(f"Response Content (first 100): {res.text[:100]}")
        all_records = res.json()
        
        print(f"Total raw records returned from API: {len(all_records)}")

        course_map = {}
        for item in all_records:
            code = (item.get("CourseCode") or "").strip()
            sec = str(item.get("SectionName") or "").strip()
            if not code or not sec: continue
            
            key = f"{code}_{sec}"
            if key not in course_map:
                course_map[key] = True # Just counting unique sections

        print(f"Total unique sections found: {len(course_map)}")
        
        if len(course_map) >= 1800:
            print("VERIFIED: The 'Master Fetch' method captured the full offering (over 1800 sections).")
        else:
            print(f"WARNING: Still only seeing {len(course_map)} sections. Needs further investigation.")

if __name__ == "__main__":
    tester = ScraperTester("2025-2-50-009", "rHrakib12@#")
    if tester.login():
        print("Login Success!")
        tester.test_sync("Summer 2026")
    else:
        print("Login Failed.")
