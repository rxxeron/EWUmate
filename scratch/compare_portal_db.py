import requests
from bs4 import BeautifulSoup
import json

def get_portal_sections():
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
    payload = {'Username': '2025-2-50-009', 'Password': 'rHrakib12@#', 'FirstNo': f, 'SecondNo': s, 'Answer': str(int(f)+int(s))}
    session.post("https://portal.ewubd.edu/Account/Login", data=payload)
    
    # Fetch Master List for Summer 2026 (ID 140)
    res = session.get("https://portal.ewubd.edu/api/utility/GetAllOfferedCourses?deptid=0&semesterid=140")
    if res.status_code != 200:
        print(f"Portal API Error: {res.status_code} - {res.text}")
        return set()
    
    data = res.json()
    sections = set()
    for item in data:
        code, sec = (item.get("CourseCode") or "").strip(), str(item.get("SectionName") or "").strip()
        if code and sec: sections.add(f"{code}_{sec}")
    return sections

def get_db_sections():
    url = "https://jwygjihrbwxhehijldiz.supabase.co/rest/v1/courses_summer2026?select=course_code,section_number"
    headers = {
        "apikey": "REDACTED_SUPABASE_SERVICE_ROLE_KEY",
        "Authorization": "Bearer REDACTED_SUPABASE_SERVICE_ROLE_KEY"
    }
    
    all_db_sections = set()
    offset = 0
    limit = 1000
    while True:
        res = requests.get(f"{url}&limit={limit}&offset={offset}", headers=headers).json()
        if not res: break
        for r in res:
            all_db_sections.add(f"{r['course_code']}_{r['section_number']}")
        if len(res) < limit: break
        offset += limit
    return all_db_sections

portal_set = get_portal_sections()
db_set = get_db_sections()

new_sections = portal_set - db_set
print(f"Total in Portal: {len(portal_set)}")
print(f"Total in Database: {len(db_set)}")
print(f"New sections discovered: {len(new_sections)}")

if new_sections:
    print("\nExamples of newly discovered sections (NOT in current DB):")
    for s in sorted(list(new_sections))[:20]:
        print(f" - {s}")
