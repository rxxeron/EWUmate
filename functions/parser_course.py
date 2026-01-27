import re
from datetime import datetime
import pdfplumber

def parse_time_to_minutes(time_str):
    """Parse time string like '08:30 AM' to minutes from midnight."""
    try:
        time_str = time_str.strip().upper()
        dt = datetime.strptime(time_str, "%I:%M %p")
        return dt.hour * 60 + dt.minute
    except:
        return 0

def get_session_duration_minutes(start_time, end_time):
    """Calculate session duration in minutes."""
    start = parse_time_to_minutes(start_time)
    end = parse_time_to_minutes(end_time)
    return end - start if end > start else 0

def detect_session_type(start_time, end_time):
    """Detect if session is Lab or Theory based on duration."""
    duration = get_session_duration_minutes(start_time, end_time)
    if duration >= 110:  # 1h 50m or more = Lab
        return "Lab"
    return "Theory"

def parse_course_pdf(pdf_path, semester_id, course_titles=None):
    course_map = {}
    
    code_start_pattern = re.compile(r"^([A-Z]{2,4}\d{3,4}[A-Z]?)")
    time_pattern = re.compile(r"(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)\s*-\s*\d{1,2}:\d{2}\s*(?:AM|PM|am|pm))", re.IGNORECASE)
    capacity_pattern = re.compile(r"(\d+/\d+)")

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            if not text: continue
            
            lines = text.split('\\n')
            for line in lines:
                time_match = time_pattern.search(line)
                
                code, section, faculty, capacity = "", "", "", "0/0"
                startTime, endTime, day_str, room = "", "", "", ""
                
                if time_match:
                    full_time = time_match.group(1)
                    start_idx, end_idx = time_match.start(), time_match.end()
                    
                    pre_time_text = line[:start_idx].strip()
                    post_time_text = line[end_idx:].strip()
                    
                    time_parts = full_time.split('-')
                    if len(time_parts) == 2:
                        startTime = time_parts[0].strip().upper()
                        endTime = time_parts[1].strip().upper()
                        
                    tokens = pre_time_text.split()
                    
                    day_tokens = []
                    remaining_tokens = list(tokens)
                    
                    while remaining_tokens:
                         curr = remaining_tokens[-1].replace(',', '').upper()
                         if len(curr) <= 3 and all(c in 'SMTWRFA' for c in curr):
                             day_tokens.insert(0, curr)
                             remaining_tokens.pop()
                         else:
                             break
                    
                    day_str = " ".join(day_tokens)
                    room = post_time_text.strip()
                    
                    if not remaining_tokens: continue
                    
                    code = remaining_tokens[0].upper()
                    section = remaining_tokens[1] if len(remaining_tokens) > 1 else ""
                    
                    if len(remaining_tokens) > 2:
                        faculty_capacity_str = " ".join(remaining_tokens[2:])
                        cap_match = capacity_pattern.search(faculty_capacity_str)
                        if cap_match:
                            capacity = cap_match.group(1)
                            faculty = faculty_capacity_str.replace(capacity, "").strip()
                        else:
                            faculty = faculty_capacity_str
                            
                    if not room: room = "TBA"
                    if not day_str: day_str = "TBA"

                else:
                    tokens = line.split()
                    if len(tokens) < 2: continue
                    code, section = tokens[0].upper(), tokens[1]
                    room, day_str = ("Online", "TBA") if "Online" in line else ("TBA", "TBA")

                session_type = "Theory"
                if startTime and endTime:
                    session_type = detect_session_type(startTime, endTime)

                session = {
                    "type": session_type, "day": day_str, "startTime": startTime,
                    "endTime": endTime, "room": room, "faculty": faculty
                }

                course_key = f"{code}_{section}"
                if course_key not in course_map:
                    course_name, credits_val = "", 0.0
                    if course_titles:
                           key_to_use = None
                           if code in course_titles:
                               key_to_use = code
                           else:
                               match_code = re.match(r"([A-Z]+)(\d+.*)", code)
                               if match_code:
                                   spaced_code = f"{match_code.group(1)} {match_code.group(2)}"
                                   if spaced_code in course_titles:
                                       key_to_use = spaced_code
                           if key_to_use:
                               meta_data = course_titles.get(key_to_use, {})
                               course_name = meta_data.get("name", "")
                               credits_val = _parse_credits(meta_data.get("credits", "0"))
                               
                    course_map[course_key] = {
                        "docId": f"course_{code}_{section}", "code": code, "courseName": course_name,
                        "section": section, "credits": credits_val, "capacity": capacity,
                        "semester": semester_id, "type": "COURSE", "sessions": []
                    }
                
                course_map[course_key]["sessions"].append(session)
    
    return list(course_map.values())

def _parse_credits(val):
    if not val: return 0.0
    try:
        return sum(float(p.strip()) for p in str(val).split('+') if p.strip())
    except:
        return 0.0
