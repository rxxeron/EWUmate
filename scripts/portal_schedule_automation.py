"""
EWU Portal Automation: Fetch My Class Schedule
Logs in to portal.ewubd.edu, selects the active semester, and extracts:
- Course Code & Section
- Credit Hours
- Timing & Room Number
- Faculty Name, Initial & Email
- Withdrawal / Drop Status
"""

import requests
from bs4 import BeautifulSoup
import json
from typing import Dict, Any, List, Optional


class EWUPortalScraper:
    BASE_URL = "https://portal.ewubd.edu"

    def __init__(self, username: str, password: str):
        self.username = username
        self.password = password
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/120.0.0.0 Safari/537.36"
            ),
            "Referer": f"{self.BASE_URL}/",
        })

    def login(self) -> bool:
        """Solves portal math captcha and logs in."""
        login_page_url = f"{self.BASE_URL}/Account/Login"
        resp = self.session.get(login_page_url, timeout=15)
        soup = BeautifulSoup(resp.text, "html.parser")

        f_no_elem = soup.find("input", {"name": "FirstNo"})
        s_no_elem = soup.find("input", {"name": "SecondNo"})

        if not f_no_elem or not s_no_elem:
            raise RuntimeError("Failed to find captcha inputs on login page.")

        f_no = int(f_no_elem.get("value", 0))
        s_no = int(s_no_elem.get("value", 0))
        answer = f_no + s_no

        payload = {
            "Username": self.username,
            "Password": self.password,
            "FirstNo": str(f_no),
            "SecondNo": str(s_no),
            "Answer": str(answer),
        }

        login_res = self.session.post(login_page_url, data=payload, allow_redirects=True, timeout=15)
        
        if "Account/Login" in login_res.url and "Invalid" in login_res.text:
            return False
            
        return "Home/Index" in login_res.url or "ASP.NET_SessionId" in self.session.cookies

    def get_semesters(self) -> List[Dict[str, Any]]:
        """Fetch list of semesters from the portal."""
        headers = {
            "X-Requested-With": "XMLHttpRequest",
            "Accept": "application/json, text/plain, */*",
        }
        res = self.session.get(f"{self.BASE_URL}/api/utility/GetSemesterForDropDown", headers=headers, timeout=15)
        res.raise_for_status()
        return res.json()

    def get_active_semester(self) -> Optional[Dict[str, Any]]:
        """Get the active / latest semester."""
        semesters = self.get_semesters()
        if not semesters:
            return None
        # Semesters are returned in descending order; index 0 is the current/active semester
        return semesters[0]

    def get_class_schedule(self, semester_id: int) -> List[Dict[str, Any]]:
        """Fetches student course schedule & faculty info for a specific semester."""
        headers = {
            "X-Requested-With": "XMLHttpRequest",
            "Accept": "application/json, text/plain, */*",
        }
        url = f"{self.BASE_URL}/api/Advising/GetSemesterStudentWiseAdvisingCourseListStudent/{semester_id}"
        res = self.session.get(url, headers=headers, timeout=15)
        res.raise_for_status()
        raw_courses = res.json()

        cleaned_schedule = []
        for item in raw_courses:
            cleaned_schedule.append({
                "course_code": item.get("CourseCode"),
                "section": item.get("SectionName"),
                "credit_hours": item.get("CreditHour"),
                "timing": item.get("TimeSlotName"),
                "room": item.get("RoomName"),
                "faculty_initial": item.get("ShortName"),
                "faculty_name": item.get("FacultyName"),
                "faculty_email": item.get("Email"),
                "withdraw_status": item.get("WithDrawStatus"),
                "drop_status": item.get("DropStatus"),
            })
        return cleaned_schedule


if __name__ == "__main__":
    username = "2025-2-50-009"
    password = "Rhrakib12@#"

    scraper = EWUPortalScraper(username, password)
    print(f"Logging in as {username}...")
    if not scraper.login():
        print("Login failed! Please check credentials.")
        exit(1)
    print("Login successful!\n")

    active_sem = scraper.get_active_semester()
    if not active_sem:
        print("No semesters found.")
        exit(1)

    sem_id = active_sem.get("SemesterId")
    sem_name = active_sem.get("SemesterName")
    print(f"Active Semester: {sem_name} (ID: {sem_id})\n")

    schedule = scraper.get_class_schedule(sem_id)
    print(f"Total Courses / Sections: {len(schedule)}\n" + "=" * 60)

    for idx, c in enumerate(schedule, 1):
        print(f"[{idx}] {c['course_code']} (Section {c['section']})")
        print(f"    Credits: {c['credit_hours']}")
        print(f"    Timing:  {c['timing']}")
        print(f"    Room:    {c['room']}")
        print(f"    Faculty: {c['faculty_name']} ({c['faculty_initial']})")
        print(f"    Email:   {c['faculty_email']}")
        print(f"    Status:  Withdraw={c['withdraw_status']}, Drop={c['drop_status']}")
        print("-" * 60)
