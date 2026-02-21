import email
from email import policy
import re
import logging

def parse_advising_eml(eml_bytes, semester_code):
    """
    Parses EML content (bytes) and returns a list of advising slot dictionaries.
    Adapted from legacy advising_parser.py.
    """
    try:
        msg = email.message_from_bytes(eml_bytes, policy=policy.default)
    except Exception as e:
        logging.error(f"Failed to parse EML bytes: {e}")
        return []
    
    body = ""
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_type() == 'text/plain':
                payload = part.get_payload(decode=True)
                if payload:
                    body = payload.decode('utf-8', errors='replace')
                break
    else:
        payload = msg.get_payload(decode=True)
        if payload and isinstance(payload, bytes):
            body = payload.decode('utf-8', errors='replace')

    if not body:
        logging.warning("No body found in EML.")
        return []

    lines = [l.strip() for l in body.split('\n') if l.strip()]
    slots = []
    
    # Regexes
    # Date: "03 December 2025" or "01-02 December 2025"
    date_pat = re.compile(r"^(\d{1,2}(?:-\d{1,2})?)\s+([A-Za-z]+)\s+(\d{4})$")
    
    # Time: "06:00 P.M.- 06:50 P.M.", "09:00 am–04:00 pm"
    time_pat = re.compile(r"(\d{1,2}:\d{2})\s*([APap]\.?[Mm]\.?)?.*?(\d{1,2}:\d{2})\s*([APap]\.?[Mm]\.?)?")

    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check Date
        match_date = date_pat.match(line)
        if match_date:
            date_str = line
            
            # Look ahead for time (usually within next 6 lines)
            for j in range(1, 7):
                if i + j >= len(lines): break
                sub = lines[i+j]
                
                # Check Time
                match_time = time_pat.search(sub)
                if match_time:
                    # Found time
                    criteria_text = " ".join(lines[i+1 : i+j])
                    
                    # Clean up time values
                    start = match_time.group(1)
                    end = match_time.group(3)
                    if match_time.group(2): 
                        start += " " + match_time.group(2).replace(".","").upper()
                    if match_time.group(4): 
                        end += " " + match_time.group(4).replace(".","").upper()
                    
                    start_clean = start.strip()
                    end_clean = end.strip()

                    # Parse credits and depts from criteria
                    min_c, max_c, depts = _parse_criteria(criteria_text)

                    slots.append({
                        "date": date_str,
                        "start_time": start_clean,
                        "end_time": end_clean,
                        "criteria_raw": criteria_text,
                        "min_credits": min_c,
                        "max_credits": max_c,
                        "allowed_departments": depts,
                        "semester": semester_code
                    })
                    i += j # Skip processed lines
                    break
        i += 1

    return slots

def _parse_criteria(criteria):
    """
    Extracts min/max credits and departments from the criteria string.
    """
    criteria_lower = criteria.lower()
    min_c = 0.0
    max_c = 999.0
    target_depts = []

    # Credit patterns
    above_match = re.search(r"(\d+(\.\d+)?)\s*credits?\s*&\s*above", criteria_lower)
    range_match = re.search(r"(\d+(\.\d+)?)\s*[-–]\s*(\d+(\.\d+)?)", criteria_lower)
    
    if above_match:
        min_c = float(above_match.group(1))
        max_c = 999.0
    elif range_match:
        v1 = float(range_match.group(1))
        v3 = float(range_match.group(3))
        min_c = min(v1, v3)
        max_c = max(v1, v3)
    
    # Departments
    known_depts = ["CSE", "EEE", "ECE", "BBA", "ECO", "ENG", "SOC", "GEB", "PHR", "B.PHARM", "LAW", "MATH", "POP", "MPS", "IS", "PPHS", "ICE", "DSA", "CE"]
    for d in known_depts:
        if re.search(r"\b" + re.escape(d.lower()) + r"\b", criteria_lower):
            target_depts.append(d)
            
    return min_c, max_c, target_depts
