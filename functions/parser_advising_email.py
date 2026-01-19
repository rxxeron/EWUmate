import email
from email import policy
from email.parser import BytesParser
import re
import firebase_admin
from firebase_admin import credentials, firestore
import sys
import os
from datetime import datetime

def parse_eml(file_path):
    with open(file_path, 'rb') as fp:
        msg = BytesParser(policy=policy.default).parse(fp)
    
    # Extract plain text body
    body = ""
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_type() == 'text/plain':
                body = part.get_content()
                break
    else:
        body = msg.get_content()

    lines = body.split('\n')
    slots = []
    
    current_date = None
    
    # Regex Patterns
    date_pattern = re.compile(r'(\d{2}) ([A-Za-z]+) (\d{4})')
    # Examples: "120.5 Credits & above", "115.5-120 Credits", "0.5-10 Credits"
    credit_pattern = re.compile(r'(\d+\.?\d*)\s*(?:-|Credits|&)\s*(\d+\.?\d*)?')
    time_pattern = re.compile(r'(\d{2}:\d{2})\s*([AP]\.M\.)\s*-\s*(\d{2}:\d{2})\s*([AP]\.M\.)', re.IGNORECASE)

    # State
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        
        if not line:
            i += 1
            continue

        # Check Date
        d_match = date_pattern.fullmatch(line)
        if d_match:
            current_date = line
            # Look ahead for credits
            j = i + 1
            credit_range = None
            time_range = None
            
            # Simple lookahead window of 10 lines
            while j < min(len(lines), i + 10):
                l2 = lines[j].strip()
                if not l2: 
                    j += 1
                    continue
                
                # Check Credits
                if not credit_range and ("Credit" in l2):
                    c_match = credit_pattern.search(l2)
                    if c_match:
                        min_c = float(c_match.group(1))
                        max_c = 999.0
                        if "& above" in l2 or "&" in l2:
                             max_c = 999.0
                        elif c_match.group(2):
                             max_c = float(c_match.group(2))
                        elif "-" in l2: 
                             # Handle "10.5-11 Credits" if regex missed group 2
                             parts = l2.split('-')
                             if len(parts) >= 2:
                                 try:
                                     # Extract first number from parts[0]
                                     p1 = re.search(r'(\d+\.?\d*)', parts[0]).group(1)
                                     # Extract number from parts[1]
                                     p2 = re.search(r'(\d+\.?\d*)', parts[1]).group(1)
                                     min_c = float(p1)
                                     max_c = float(p2)
                                 except: pass
                        
                        credit_range = {'min': min_c, 'max': max_c}
                
                # Check Time
                if not time_range and ("M." in l2 or "m." in l2): # Matches P.M., A.M.
                    t_match = time_pattern.search(l2)
                    if t_match:
                        start_str = f"{t_match.group(1)} {t_match.group(2)}"
                        end_str = f"{t_match.group(3)} {t_match.group(4)}"
                        time_range = {'start': start_str, 'end': end_str}
                
                if credit_range and time_range:
                    break
                j += 1
            
            if current_date and credit_range and time_range:
                # Construct Slot
                # Parse DateTime objects
                # Date format: 03 December 2025
                # Time format: 06:00 P.M.
                try:
                    fmt = "%d %B %Y %I:%M %p"
                    # Fix P.M. -> PM for parsing if needed
                    start_clean = time_range['start'].replace('.','').upper()
                    end_clean = time_range['end'].replace('.','').upper()
                    
                    start_dt = datetime.strptime(f"{current_date} {start_clean}", fmt)
                    end_dt = datetime.strptime(f"{current_date} {end_clean}", fmt)
                    
                    slots.append({
                        'minCredits': credit_range['min'],
                        'maxCredits': credit_range['max'],
                        'startTime': start_dt,
                        'endTime': end_dt,
                        'displayTime': f"{current_date}, {time_range['start']}-{time_range['end']}"
                    })
                    i = j # Advance
                except Exception as e:
                    print(f"Error parsing date/time: {e} | {current_date} {time_range}")
        
        i += 1
    
    return slots

def upload_schedule(slots, semester_code="Spring2026"):
    # Initialize Firestore
    if not firebase_admin._apps:
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    
    # Clean slots for Firestore (Datetime is compatible)
    doc_ref = db.collection('advising_schedules').document(semester_code)
    doc_ref.set({
        'semester': semester_code,
        'slots': slots,
        'uploadedAt': firestore.SERVER_TIMESTAMP
    })
    print(f"Uploaded {len(slots)} slots to advising_schedules/{semester_code}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python parser_advising_email.py <path_to_eml_file>")
        sys.exit(1)
        
    fpath = sys.argv[1]
    parsed_slots = parse_eml(fpath)
    
    for s in parsed_slots:
        print(f"[{s['minCredits']}-{s['maxCredits']}] : {s['startTime']} - {s['endTime']}")
        
    # Uncomment to upload actually
    upload_schedule(parsed_slots)
