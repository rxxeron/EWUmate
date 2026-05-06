import requests
from bs4 import BeautifulSoup
import json

def get_physical_sections():
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
    
    # Fetch Master List
    res = session.get("https://portal.ewubd.edu/api/utility/GetAllOfferedCourses?deptid=0&semesterid=140")
    data = res.json()
    
    physical_map = {}
    for item in data:
        # A physical section is defined by Faculty, Time, and Room
        # Note: Some sections have multiple slots, we need to consider the whole schedule
        code = (item.get("CourseCode") or "").strip()
        sec = str(item.get("SectionName") or "").strip()
        faculty = (item.get("ShortName") or "TBA").strip()
        time = (item.get("TimeSlotName") or "").strip()
        room = (item.get("RoomCode") or "TBA").strip()
        
        if not code or not sec: continue
        
        # We'll group by (Code, Sec) first to get the full schedule
        course_key = f"{code}_{sec}"
        if course_key not in physical_map:
            physical_map[course_key] = []
        physical_map[course_key].append(f"{faculty}|{time}|{room}")

    # Now deduplicate the "Physical Classes"
    # A physical class might have multiple codes
    unique_physical_classes = {}
    for key, schedule in physical_map.items():
        sched_key = tuple(sorted(schedule))
        if sched_key not in unique_physical_classes:
            unique_physical_classes[sched_key] = []
        unique_physical_classes[sched_key].append(key)

    print(f"Total Course-Sections returned by API: {len(physical_map)}")
    print(f"Total Unique Physical Classes (Deduplicated by Faculty/Time/Room): {len(unique_physical_classes)}")
    
    # Find examples of multiple codes for same physical class
    duplicates = {k: v for k, v in unique_physical_classes.items() if len(v) > 1}
    print(f"Number of Physical Classes with multiple course codes: {len(duplicates)}")
    
    if duplicates:
        print("\nExamples of shared sections:")
        for sched, codes in list(duplicates.items())[:10]:
            print(f" - Codes: {codes} | Schedule: {sched}")

get_physical_sections()
