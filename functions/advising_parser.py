
import email
from email import policy
import re
import json
import os

def parse_advising_email_content(content_bytes):
    """
    Parses EML content (bytes) and returns a list of raw slot dictionaries.
    """
    msg = email.message_from_bytes(content_bytes, policy=policy.default)
    
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
        if payload:
            body = payload.decode('utf-8', errors='replace')

    if not body:
        return []

    lines = [l.strip() for l in body.split('\n') if l.strip()]
    slots = []
    
    # Regexes
    # Date: "03 December 2025" or "01-02 December 2025"
    date_pat = re.compile(r"^(\d{1,2}(?:-\d{1,2})?)\s+([A-Za-z]+)\s+(\d{4})$")
    
    # Time: "06:00 P.M.- 06:50 P.M.", "09:00 am–04:00 pm"
    # Use non-greedy match for separator
    time_pat = re.compile(r"(\d{1,2}:\d{2})\s*([APap]\.?[Mm]\.?)?.*?(\d{1,2}:\d{2})\s*([APap]\.?[Mm]\.?)?")

    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check Date
        match_date = date_pat.match(line)
        if match_date:
            date_str = line
            
            found_time = False
            for j in range(1, 7):
                if i + j >= len(lines): break
                sub = lines[i+j]
                
                # Check Time
                match_time = time_pat.search(sub)
                if match_time:
                    # Found time
                    criteria_list = lines[i+1 : i+j]
                    criteria_text = " ".join(criteria_list)
                    
                    # Clean up time
                    start = match_time.group(1)
                    end = match_time.group(3)
                    if match_time.group(2): start += " " + match_time.group(2).replace(".","").upper()
                    if match_time.group(4): end += " " + match_time.group(4).replace(".","").upper()
                    
                    start_clean = start.strip()
                    end_clean = end.strip()

                    slots.append({
                        "date": date_str,
                        "criteria": criteria_text,
                        "raw_time": sub,
                        "start_time": start_clean,
                        "end_time": end_clean,
                    })
                    found_time = True
                    i += j 
                    break
            
        i += 1

    return slots

def parse_credits_from_criteria(criteria):
    criteria = criteria.lower()
    min_c = 0.0
    max_c = 999.0
    target_depts = []

    above_match = re.search(r"(\d+(\.\d+)?)\s*credits?\s*&\s*above", criteria)
    range_match = re.search(r"(\d+(\.\d+)?)\s*[-–]\s*(\d+(\.\d+)?)", criteria)
    
    if above_match:
        min_c = float(above_match.group(1))
        max_c = 999.0
    elif range_match:
        v1 = float(range_match.group(1))
        v3 = float(range_match.group(3))
        min_c = min(v1, v3)
        max_c = max(v1, v3)
    
    known_depts = ["CSE", "EEE", "ECE", "BBA", "ECO", "ENG", "SOC", "GEB", "PHR", "B.PHARM", "LAW", "MATH", "POP", "MPS", "IS", "PPHS", "ICE", "DSA", "CE"]
    for d in known_depts:
        d_esc = re.escape(d.lower())
        if re.search(r"\b" + d_esc + r"\b", criteria):
            target_depts.append(d)
            
    return min_c, max_c, target_depts

def process_slots(slots):
    final = []
    for s in slots:
        min_c, max_c, depts = parse_credits_from_criteria(s['criteria'])
        
        # Unique ID
        uid = f"{s['date']}_{s['start_time']}".replace(" ", "").replace(":","")
        if depts:
            uid += "_" + "_".join(depts)
            
        final.append({
            "slotId": uid,
            "date": s['date'],
            "startTime": s['start_time'],
            "endTime": s['end_time'],
            "criteriaRaw": s['criteria'],
            "minCredits": min_c,
            "maxCredits": max_c,
            "allowedDepartments": depts
        })
    return final
