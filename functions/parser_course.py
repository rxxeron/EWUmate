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
    # Temporary storage: key = "CODE_SECTION", value = course data with sessions list
    course_map = {}
    
    # Regex to confirm line starts with a specific Course Code format (e.g., CSE101)
    # This prevents processing garbage lines.
    code_start_pattern = re.compile(r"^([A-Z]{2,4}\d{3,4}[A-Z]?)")
    
    # Time pattern: 08:30 AM - 10:00 AM (Case insensitive, flexible spaces)
    time_pattern = re.compile(r"(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)\s*-\s*\d{1,2}:\d{2}\s*(?:AM|PM|am|pm))", re.IGNORECASE)

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            if not text: continue
            
            lines = text.split('\n')
            for line in lines:
            


                # We prioritize finding the time to split the line into "Metadata" and "Schedule Info"
                time_match = time_pattern.search(line)
                
                code = ""
                section = ""
                faculty = ""
                capacity = "0"
                
                startTime = ""
                endTime = ""
                day_str = ""
                room = ""
                
                if time_match:
                    full_time = time_match.group(1)
                    start_idx = time_match.start()
                    end_idx = time_match.end()
                    
                    # Split chunks
                    # Pre-Time: Code, Section, Capacity, Faculty, DAY
                    # Post-Time: Room
                    pre_time_text = line[:start_idx].strip()
                    post_time_text = line[end_idx:].strip()
                    
                    # Parse Time
                    time_parts = full_time.split('-')
                    if len(time_parts) == 2:
                        startTime = time_parts[0].strip().upper()
                        endTime = time_parts[1].strip().upper()
                        
                    # Parse Pre-Time Tokens
                    tokens = pre_time_text.split()
                    
                    # Heuristic: Scan from RIGHT of pre-time to find Day(s) 
                    day_tokens = []
                    remaining_tokens = list(tokens)
                    
                    while remaining_tokens:
                         curr = remaining_tokens[-1].replace(',', '').upper()
                         # Is it a valid day token? (Allowing for 'S', 'T', 'MW', etc.)
                         if len(curr) <= 3 and all(c in 'SMTWRFA' for c in curr):
                             day_tokens.insert(0, curr)
                             remaining_tokens.pop()
                         else:
                             break
                    
                    day_str = " ".join(day_tokens)
                    room = post_time_text.strip() # Room is everything after time
                    
                    if not remaining_tokens: continue
                    
                    code = remaining_tokens[0].upper()
                    section = remaining_tokens[1] if len(remaining_tokens) > 1 else ""
                    
                    # Faculty/Capacity in middle
                    # capacity 00/00 or 00
                    # faculty Alphabet
                    
                    # We can pick faculty as remaining tokens [2:-1] or similar
                    if len(remaining_tokens) > 2:
                        # Simple join for faculty, ignoring capacity for now
                         faculty = " ".join(remaining_tokens[2:])

                    if not room: room = "TBA"
                    if not day_str: day_str = "TBA"

                else:
                    # Fallback for "Online" or TBA times lines
                    # We still need Code/Section
                    tokens = line.split()
                    if len(tokens) < 2: continue
                    
                    code = tokens[0].upper()
                    section = tokens[1]
                    
                    if "Online" in line:
                         room = "Online"
                         day_str = "TBA"
                    else:
                         room = "TBA"
                         day_str = "TBA"

                # Detect session type based on duration (if time exists)
                session_type = "Theory"
                if startTime and endTime:
                    session_type = detect_session_type(startTime, endTime)

                # Create session object
                session = {
                    "type": session_type,
                    "day": day_str,
                    "startTime": startTime,
                    "endTime": endTime,
                    "room": room,
                    "faculty": faculty
                }

                # Group by code + section
                course_key = f"{code}_{section}"
                
                if course_key not in course_map:
                    # Metadata lookup (titles/credits)
                    course_name = ""
                    credits_val = 0.0
                    
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
                               meta_data = course_titles[key_to_use]
                               if isinstance(meta_data, dict):
                                   course_name = meta_data.get("name", "")
                                   raw_credits = meta_data.get("credits", "0")
                                   credits_val = _parse_credits(raw_credits)
                               elif isinstance(meta_data, str):
                                   course_name = meta_data

                    course_map[course_key] = {
                        "docId": f"course_{code}_{section}",
                        "code": code,
                        "courseName": course_name,
                        "section": section,
                        "credits": credits_val,
                        "capacity": "0", # Simplified
                        "semester": semester_id,
                        "type": "COURSE",
                        "sessions": []
                    }
                
                # Add session to course
                course_map[course_key]["sessions"].append(session)
    
    # Convert map to list
    courses = list(course_map.values())
    return courses

def _parse_credits(val):
    """Parses credits string, handling '3+1' sums."""
    if not val: return 0.0
    try:
        parts = str(val).split('+')
        return sum(float(p.strip()) for p in parts if p.strip())
    except:
        return 0.0
