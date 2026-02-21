import re
from datetime import datetime
import pdfplumber
import logging

def parse_time_to_minutes(time_str):
    """Parse time string like '08:30 AM' to minutes from midnight."""
    try:
        if not time_str: return 0
        time_str = time_str.strip().upper()
        # Handle cases like "08:30AM" (no space)
        if "AM" in time_str and " " not in time_str:
             time_str = time_str.replace("AM", " AM")
        if "PM" in time_str and " " not in time_str:
             time_str = time_str.replace("PM", " PM")

        dt = datetime.strptime(time_str, "%I:%M %p")
        return dt.hour * 60 + dt.minute
    except:
        return 0

def get_session_duration_minutes(start_time, end_time):
    """Calculate session duration in minutes."""
    start = parse_time_to_minutes(start_time)
    end = parse_time_to_minutes(end_time)
    if end < start: # Handle crossing midnight? Unlikely for classes.
        return 0
    return end - start

def detect_session_type(start_time, end_time):
    """Detect if session is Lab or Theory based on duration."""
    duration = get_session_duration_minutes(start_time, end_time)
    # 1h 30m = 90min (Theory)
    # 3h = 180min (Lab)
    # 1h 50m = 110min (Lab sometimes?) 
    # Let's stick to the heuristic: >= 110 minutes is Lab. 
    # Standard theory is 90 mins.
    if duration >= 110:
        return "Lab"
    return "Theory"

def _parse_credits(val):
    if not val: return 0.0
    try:
        # Handle "3" or "3.0" or "1+2"
        return sum(float(p.strip()) for p in str(val).split('+') if p.strip())
    except:
        return 0.0

def parse_course_pdf(pdf_file, semester_id, course_titles=None):
    """
    Parses course PDF.
    pdf_file: file-like object (bytes) or path.
    semester_id: str ("Spring2026")
    course_titles: dict (code -> metadata) for looking up names/credits.
    """
    course_map = {}
    
    # Regex Patterns
    # Matches course codes like CSE101, ENG101 (2-4 letters, 3-4 digits, optional suffix)
    code_pattern = re.compile(r"^[A-Z]{2,4}\d{3,4}[A-Z]?$")
    # Matches time ranges like 08:30 AM - 10:00 AM
    time_pattern = re.compile(r"(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)\s*-\s*\d{1,2}:\d{2}\s*(?:AM|PM|am|pm))", re.IGNORECASE)
    # Matches capacity like 30/40 or 0/0, allowing spaces
    capacity_token_pattern = re.compile(r"^(\d+)\s*/\s*(\d+)$")

    try:
        with pdfplumber.open(pdf_file) as pdf:
            for page in pdf.pages:
                text = page.extract_text()
                if not text: continue
                
                lines = text.split('\n')
                for line in lines:
                    # 1. Identify Time Range to split the line
                    time_match = time_pattern.search(line)
                    
                    code, section, faculty, capacity = "", "", "", "0/0"
                    startTime, endTime, day_str, room = "", "", "", ""
                    
                    if time_match:
                        full_time = time_match.group(1)
                        start_idx, end_idx = time_match.start(), time_match.end()
                        
                        pre_time_text = line[:start_idx].strip()
                        post_time_text = line[end_idx:].strip() # Room is usually after time
                        
                        # Parse Time
                        time_parts = full_time.split('-')
                        if len(time_parts) == 2:
                            startTime = time_parts[0].strip().upper()
                            endTime = time_parts[1].strip().upper()
                            
                        # Tokenize the left side: CODE SECTION FACULTY... CAPACITY DAY...
                        tokens = pre_time_text.split()
                        if not tokens: continue

                        # A. Extract Days from the END of the left side
                        day_tokens = []
                        while tokens:
                            curr = tokens[-1].replace(',', '').upper()
                            # specific check for day abbreviations
                            if len(curr) <= 3 and all(c in 'SMTWRFA' for c in curr):
                                day_tokens.insert(0, curr)
                                tokens.pop()
                            else:
                                break
                        day_str = " ".join(day_tokens) if day_tokens else "TBA"

                        if not tokens: continue # Should have code/section left

                        # B. Extract Code and Section from the START
                        code = tokens[0].upper()
                        current_idx = 1
                        
                        # Fix for Split Codes (e.g., "CSE 101" -> "CSE101")
                        if len(tokens) > 1 and code.isalpha() and tokens[1][0].isdigit():
                             code = code + tokens[1]
                             current_idx = 2

                        if len(tokens) > current_idx:
                            section = tokens[current_idx]
                            # Verify section is short (usually 1-2 chars) to avoid grabbing Faculty name part
                            # But sometimes section is just '1'. 
                            middle_tokens = tokens[current_idx+1:]
                        else:
                            section = ""
                            middle_tokens = []

                        # C. Extract Capacity and Faculty from the MIDDLE
                        # Search specifically for the capacity token (e.g. "30/40")
                        capacity_idx = -1
                        for i, tok in enumerate(middle_tokens):
                            if capacity_token_pattern.match(tok):
                                capacity_idx = i
                                capacity = tok
                                break
                        
                        if capacity_idx != -1:
                            # Faculty is everything before capacity
                            faculty_tokens = middle_tokens[:capacity_idx]
                            faculty = " ".join(faculty_tokens)
                        else:
                            # Fallback: Regex search on the joined string if token split failed
                            # e.g. "Dr.Smith30/40"
                            joined_middle = " ".join(middle_tokens)
                            cap_search = re.search(r"(\d+\s*/\s*\d+)", joined_middle)
                            if cap_search:
                                capacity = cap_search.group(1)
                                faculty = joined_middle.replace(capacity, "").strip() # This is the fallback
                            else:
                                faculty = joined_middle

                        # Extract Room from right side
                        room = post_time_text.strip()
                        if not room: room = "TBA"

                    else:
                        # Line without time (e.g. header or just code info? or online?)
                        # Handling "Online" cases if relevant
                        if "Online" in line:
                            tokens = line.split()
                            if len(tokens) >= 2:
                                code = tokens[0].upper()
                                section = tokens[1]
                                room = "Online"
                                day_str = "TBA"
                        else:
                            continue # Skip malformed lines

                    # Build Session Object
                    session_type = "Theory"
                    if startTime and endTime:
                        session_type = detect_session_type(startTime, endTime)

                    session = {
                        "type": session_type, "day": day_str, "startTime": startTime,
                        "endTime": endTime, "room": room, "faculty": faculty
                    }

                    # Add to Map
                    # Use a consistent ID generation
                    course_key = f"{code}_{section}".replace(" ", "")
                    
                    if course_key not in course_map:
                        course_name, credits_val = "", 0.0
                        # Metadata lookup (titles/credits)
                        if course_titles:
                               key_to_use = None
                               if code in course_titles:
                                   key_to_use = code
                               else:
                                   # Try spacing out code: CSE101 -> CSE 101 or CSE 101 -> CSE101
                                   match_code = re.match(r"([A-Z]+)(\d+.*)", code)
                                   if match_code:
                                       prefix = match_code.group(1)
                                       digits = match_code.group(2)
                                       
                                       # 1. Spaced Check
                                       spaced_code = f"{prefix} {digits}"
                                       if spaced_code in course_titles:
                                           key_to_use = spaced_code
                                       
                                       # 2. 4-Digit Fallback (e.g. ENG7101 -> ENG101)
                                       # Checks if we have 4 digits, tries removing the first one.
                                       elif len(digits) == 4 and digits.isdigit():
                                            fallback_digits = digits[1:] # "7101" -> "101"
                                            fallback_code = f"{prefix}{fallback_digits}"
                                            fallback_spaced = f"{prefix} {fallback_digits}"
                                            
                                            if fallback_code in course_titles:
                                                key_to_use = fallback_code
                                            elif fallback_spaced in course_titles:
                                                key_to_use = fallback_spaced
                               
                               if key_to_use:
                                   meta_data = course_titles.get(key_to_use, {})
                                   # Robust name lookup: 'name', 'title', 'courseName', 'courseTitle'
                                   course_name = meta_data.get("name") or meta_data.get("title") or meta_data.get("courseName") or meta_data.get("courseTitle") or ""
                                   if "creditVal" in meta_data:
                                       try:
                                           credits_val = float(meta_data["creditVal"])
                                       except:
                                           credits_val = _parse_credits(meta_data.get("credits", "0"))
                                   else:
                                       credits_val = _parse_credits(meta_data.get("credits", "0"))
                                   
                        course_map[course_key] = {
                            "doc_id": f"course_{code}_{section}", # Matches schema check: doc_id
                            "code": code, 
                            "course_name": course_name, # Matches schema check: course_name
                            "section": section, 
                            "credits": credits_val, # Matches schema check: credits (int/float?)
                            "capacity": capacity,
                            "semester": semester_id, 
                            "type": "COURSE", 
                            "sessions": [],
                            "faculty": faculty # Base faculty (will be overwritten if multiple sessions have different faculty? Usually same)
                        }
                        
                        # Note: Schema inspection showed 'faculty' column on the course table too.
                        # It also showed 'sessions' jsonb column.
                    
                    # Add session
                    course_map[course_key]["sessions"].append(session)
                    # Update faculty if empty (sometimes first session doesn't have it?)
                    if not course_map[course_key]["faculty"] and faculty:
                         course_map[course_key]["faculty"] = faculty

    except Exception as e:
        logging.error(f"Error parsing PDF: {e}")
        # Re-raise or return empty?
        raise e
        
    return list(course_map.values())
