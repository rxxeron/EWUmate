
import fitz # PyMuPDF
import json
import requests
import re

PDF_PATH = r"C:\Users\Farzana Safa\Downloads\Updated_Faculty_List_Summer-2026.2026-05-01.21-28-48 (1).pdf"
SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMDQxNzQsImV4cCI6MjA4NjY4MDE3NH0.zQc3dq53HBpMeN0rbJA9soF0oYhl7de1_sNnB_9JPoM"
TABLE_NAME = "courses_summer2026"

def parse_pdf(path):
    print(f"[*] Parsing PDF: {path}")
    doc = fitz.open(path)
    courses = []
    
    # Pattern to identify a course code (start of a record)
    code_pattern = re.compile(r'^[A-Z]{2,5}\d{3,4}$')
    
    all_lines = []
    for page_num in range(len(doc)):
        page = doc[page_num]
        text = page.get_text("text")
        lines = [l.strip() for l in text.split('\n') if l.strip()]
        all_lines.extend(lines)

    i = 0
    while i < len(all_lines):
        line = all_lines[i]
        
        # Look for course code
        if code_pattern.match(line):
            try:
                # We expect: Code, Sec, Faculty, Capacity, Timing, Room
                code = line
                sec = all_lines[i+1]
                faculty = all_lines[i+2]
                cap = all_lines[i+3]
                timing = all_lines[i+4]
                
                # Room can be one or more lines until the next course code
                room_parts = []
                j = i + 5
                while j < len(all_lines) and not code_pattern.match(all_lines[j]):
                    # Skip headers/footers if they appear in between
                    if "East West University" in all_lines[j] or "Offered Courses" in all_lines[j] or "ewucoursetracker" in all_lines[j]:
                        j += 1
                        continue
                    room_parts.append(all_lines[j])
                    j += 1
                
                room = " ".join(room_parts)
                
                courses.append({
                    "code": code,
                    "section": sec,
                    "faculty": faculty,
                    "capacity": cap,
                    "timing": timing,
                    "room": room
                })
                i = j # Move to the next potential record
            except IndexError:
                break
        else:
            i += 1
    
    print(f"[+] Extracted {len(courses)} records from PDF.")
    return courses

def fetch_db_data():
    print(f"[*] Fetching data from Supabase: {TABLE_NAME}")
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}"
    }
    all_data = []
    offset = 0
    limit = 1000
    
    while True:
        url = f"{SUPABASE_URL}/rest/v1/{TABLE_NAME}?select=*&offset={offset}&limit={limit}"
        response = requests.get(url, headers=headers)
        if response.status_code != 200:
            print(f"[!] Error fetching DB data: {response.text}")
            break
        
        data = response.json()
        if not data:
            break
            
        all_data.extend(data)
        if len(data) < limit:
            break
        offset += limit
        
    print(f"[+] Fetched {len(all_data)} records from DB.")
    return all_data

def compare(pdf_data, db_data):
    print("[*] Comparing data...")
    mismatches = []
    
    # Index DB data by code and section for fast lookup
    db_map = {}
    for row in db_data:
        # Use course_code and section_number from DB
        key = (row.get('course_code'), str(row.get('section_number')))
        if key not in db_map:
            db_map[key] = []
        db_map[key].append(row)

    processed_sections = set()
    
    for pdf_row in pdf_data:
        # Normalize PDF code (remove spaces if any)
        p_code = pdf_row['code'].replace(" ", "")
        p_sec = str(pdf_row['section'])
        
        key = (p_code, p_sec)
        if key not in db_map:
            mismatches.append({
                "course": p_code,
                "sec": p_sec,
                "error": "Missing in Database",
                "pdf_faculty": pdf_row['faculty']
            })
            continue
        
        db_rows = db_map[key]
        db_row = db_rows[0]
        
        # Compare Faculty
        p_fac = pdf_row['faculty'].strip().upper()
        d_fac = (db_row.get('faculty_initials') or "TBA").strip().upper()
        
        if p_fac != d_fac:
            mismatches.append({
                "course": p_code,
                "sec": p_sec,
                "error": "Faculty Mismatch",
                "pdf_val": p_fac,
                "db_val": d_fac
            })
            
        # Compare Capacity
        p_cap = pdf_row['capacity'].strip()
        d_cap = (db_row.get('capacity') or "0/0").strip()
        
        if p_cap != d_cap:
            mismatches.append({
                "course": p_code,
                "sec": p_sec,
                "error": "Capacity Mismatch",
                "pdf_val": p_cap,
                "db_val": d_cap
            })
            
    return mismatches

if __name__ == "__main__":
    pdf_courses = parse_pdf(PDF_PATH)
    db_courses = fetch_db_data()
    
    if pdf_courses and db_courses:
        results = compare(pdf_courses, db_courses)
        with open("comparison_results.json", "w") as f:
            json.dump(results, f, indent=2)
        print("[+] Comparison complete. Results saved to comparison_results.json")
    else:
        print("[!] Could not perform comparison.")
