
import email
from email import policy
import re
import json
import os
import sys

def parse_advising_email(file_path):
    print(f"Parsing: {file_path}")
    if not os.path.exists(file_path):
        print("File not found.")
        return []

    with open(file_path, 'rb') as f:
        msg = email.message_from_binary_file(f, policy=policy.default)
    
    body = ""
    # Walk to find text/plain
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_type() == 'text/plain':
                # decode=True automatically decodes quoted-printable (e.g. =C2=B7 -> ·, =E2=80=93 -> –)
                payload = part.get_payload(decode=True)
                if payload:
                    body = payload.decode('utf-8', errors='replace')
                break
    else:
        payload = msg.get_payload(decode=True)
        if payload:
            body = payload.decode('utf-8', errors='replace')

    if not body:
        print("No text body found.")
        return []

    print(f"Body length: {len(body)}")
    # print("--- BODY START ---")
    # print(body[:500])
    # print("--- BODY END ---")

    lines = [l.strip() for l in body.split('\n') if l.strip()]
    slots = []
    
    # Regexes
    # Date: "03 December 2025" or "01-02 December 2025"
    # Matches: (digits)[-(digits)]? (Month) (Year)
    date_pat = re.compile(r"^(\d{1,2}(?:-\d{1,2})?)\s+([A-Za-z]+)\s+(\d{4})$")
    
    # Time: "06:00 P.M.- 06:50 P.M.", "09:00 am–04:00 pm"
    # We look for H:M ... H:M
    # Use non-greedy match for separator
    time_pat = re.compile(r"(\d{1,2}:\d{2})\s*([APap]\.?[Mm]\.?)?.*?(\d{1,2}:\d{2})\s*([APap]\.?[Mm]\.?)?")

    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check Date
        match_date = date_pat.match(line)
        if match_date:
            date_str = line
            print(f"Found Date candidate: {date_str}")
            
            # Context search: Look ahead for Time
            # The criteria is usually between date and time
            found_time = False
            
            # Heuristic: Scan next 6 lines
            for j in range(1, 7):
                if i + j >= len(lines): break
                sub = lines[i+j]
                
                # Check Time
                match_time = time_pat.search(sub)
                if match_time:
                    # Found time!
                    # Criteria is everything between i and i+j
                    criteria_list = lines[i+1 : i+j]
                    criteria_text = " ".join(criteria_list)
                    
                    # Clean up time
                    # match_time groups: 1=Start, 2=AM/PM, 3=End, 4=AM/PM
                    start = match_time.group(1)
                    end = match_time.group(3)
                    # Normalize AM/PM if present
                    if match_time.group(2): start += " " + match_time.group(2).replace(".","").upper()
                    if match_time.group(4): end += " " + match_time.group(4).replace(".","").upper()
                    
                    start_clean = start.strip()
                    end_clean = end.strip()

                    print(f"  -> Match Time: {sub} => {start_clean} - {end_clean}")
                    print(f"  -> Criteria: {criteria_text}")

                    # Store
                    slots.append({
                        "date": date_str,
                        "criteria": criteria_text,
                        "raw_time": sub,
                        "start_time": start_clean,
                        "end_time": end_clean,
                    })
                    found_time = True
                    i += j # Advance to the time line
                    break
            
            if not found_time:
                print(f"  -> No time found for date {date_str}")
        
        i += 1

    return slots

def parse_credits_from_criteria(criteria):
    criteria = criteria.lower()
    min_c = 0.0
    max_c = 999.0
    target_depts = []

    # "120.5 Credits & above"
    above_match = re.search(r"(\d+(\.\d+)?)\s*credits?\s*&\s*above", criteria)
    
    # "115.5-120 Credits" (or 29.5-31)
    range_match = re.search(r"(\d+(\.\d+)?)\s*[-–]\s*(\d+(\.\d+)?)", criteria)
    
    if above_match:
        min_c = float(above_match.group(1))
        max_c = 999.0
    elif range_match:
        # range_match.group(1) is first number
        # range_match.group(3) is second number (because of inner group for decimal)
        v1 = float(range_match.group(1))
        v3 = float(range_match.group(3))
        min_c = min(v1, v3)
        max_c = max(v1, v3)
    
    # Departments
    known_depts = ["CSE", "EEE", "ECE", "BBA", "ECO", "ENG", "SOC", "GEB", "PHR", "B.PHARM", "LAW", "MATH", "POP", "MPS", "IS", "PPHS", "ICE", "DSA", "CE"]
    for d in known_depts:
        # Check carefully for whole word match to avoid substrings
        # e.g. "IS" in "THIS"
        # escaping regex
        d_esc = re.escape(d.lower())
        if re.search(r"\b" + d_esc + r"\b", criteria):
            target_depts.append(d)
            
    # If departments found, and no range found, it implies the specific department schedule.
    # In the email, Dept specific slots are "0.5-10 Credits" (usually found just before)
    # The parser logic combines lines between Date and Time.
    # If the email structure is:
    # Date
    # 0.5-10 Credits
    # Depts
    # Time
    # Then criteria will contain "0.5-10 Credits Depts".
    # So range parser should catch it.
    
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

if __name__ == "__main__":
    eml_file = "Online Advising of Courses for Spring Semester 2026.eml"
    print("Starting parser...")
    raw = parse_advising_email(eml_file)
    print(f"Found {len(raw)} slots.")
    
    processed = process_slots(raw)
    
    out_file = "advising_schedule.json"
    try:
        with open(out_file, 'w', encoding='utf-8') as f:
            json.dump(processed, f, indent=2)
        print(f"Saved to {out_file}")
    except Exception as e:
        print(f"Error saving file: {e}")
