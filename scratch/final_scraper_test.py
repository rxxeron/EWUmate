import os
import requests
from bs4 import BeautifulSoup
import json
import logging

# Set up logging to see what's happening
logging.basicConfig(level=logging.INFO)

class ScraperTester:
    def __init__(self, student_id, password):
        self.student_id = student_id
        self.password = password
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': 'https://portal.ewubd.edu/Home/OfferedCoursesStudent'
        })

    def login(self):
        try:
            r = self.session.get("https://portal.ewubd.edu/Account/Login", timeout=15)
            soup = BeautifulSoup(r.text, 'html.parser')
            f_no_input = soup.find('input', {'name': 'FirstNo'})
            s_no_input = soup.find('input', {'name': 'SecondNo'})
            
            if not f_no_input or not s_no_input:
                print("Could not find captcha inputs. Check if the portal URL is correct or if you're blocked.")
                return False
                
            f_no = f_no_input['value']
            s_no = s_no_input['value']
            payload = {
                'Username': self.student_id, 
                'Password': self.password, 
                'FirstNo': f_no, 
                'SecondNo': s_no, 
                'Answer': str(int(f_no)+int(s_no))
            }
            res = self.session.post("https://portal.ewubd.edu/Account/Login", data=payload, timeout=15)
            if "Home/Index" in res.url or "/Home" in res.url:
                print("Login successful!")
                return True
            else:
                print(f"Login failed. Redirected to: {res.url}")
                return False
        except Exception as e:
            print(f"Login Error: {e}")
            return False

    def test_sync(self, sem_name):
        print(f"\n--- Testing Scraper for: {sem_name} ---")
        
        # 1. Get Semester ID
        sems = self.session.get("https://portal.ewubd.edu/api/utility/GetSemesterForDropDown").json()
        normalized_target = sem_name.lower().replace(' ', '-').replace('_', '-')
        target = next((s for s in sems if normalized_target in str(s).lower().replace(' ', '-')), None)
        
        if not target: 
            print(f"Error: Semester {sem_name} not found in portal.")
            return
        
        sem_id = target.get('SemesterId') or target.get('ID')
        print(f"Targeting Semester ID: {sem_id}")

        # 2. Master Fetch: deptid=0 to get everything
        url = f"https://portal.ewubd.edu/api/utility/GetAllOfferedCourses?deptid=0&semesterid={sem_id}"
        print(f"Hitting API: {url}")
        
        try:
            res = self.session.get(url, timeout=30)
            all_records = res.json()
        except Exception as e:
            print(f"API Fetch Error: {e}")
            return

        print(f"Total raw records returned: {len(all_records)}")

        # 3. Transform & Deduplicate (Count Unique Sections)
        course_map = {}
        for item in all_records:
            code = (item.get("CourseCode") or "").strip()
            sec = str(item.get("SectionName") or "").strip()
            if not code or not sec: continue
            
            key = f"{code}_{sec}"
            if key not in course_map:
                course_map[key] = True

        print(f"TOTAL UNIQUE SECTIONS FOUND: {len(course_map)}")
        
        if len(course_map) >= 1882:
            print(f"SUCCESS: Captured {len(course_map)} sections. Goal was 1882.")
        else:
            print(f"RESULT: Found {len(course_map)} sections. (Target: 1882)")

if __name__ == "__main__":
    # Credentials from scraper_config
    tester = ScraperTester("2025-2-50-009", "rHrakib12@#")
    if tester.login():
        tester.test_sync("Summer 2026")
    else:
        print("Scraper test aborted due to login failure.")
