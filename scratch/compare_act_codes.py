import requests
from bs4 import BeautifulSoup
import json

def get_course_details(target_codes):
    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'X-Requested-With': 'XMLHttpRequest',
        'Referer': 'https://portal.ewubd.edu/Home/OfferedCoursesStudent'
    })
    # Login
    r = session.get("https://portal.ewubd.edu/Account/Login")
    soup = BeautifulSoup(r.text, 'html.parser')
    f, s = soup.find('input', {'name': 'FirstNo'})['value'], soup.find('input', {'name': 'SecondNo'})['value']
    session.post("https://portal.ewubd.edu/Account/Login", data={'Username': '2025-2-50-009', 'Password': 'rHrakib12@#', 'FirstNo': f, 'SecondNo': s, 'Answer': str(int(f)+int(s))})
    
    # Fetch Master List for Summer 2026 (ID 140)
    res = session.get("https://portal.ewubd.edu/api/utility/GetAllOfferedCourses?deptid=0&semesterid=140")
    data = res.json()
    
    results = {}
    for item in data:
        code = (item.get("CourseCode") or "").strip()
        if code in target_codes:
            if code not in results: results[code] = []
            results[code].append({
                "sec": str(item.get("SectionName")),
                "faculty": item.get("ShortName"),
                "time": item.get("TimeSlotName"),
                "room": item.get("RoomCode")
            })
    return results

details = get_course_details(["ECO101", "ECO7101"])
print(json.dumps(details, indent=2))
