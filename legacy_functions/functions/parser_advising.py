import email
from email import policy
from email.parser import BytesParser
import re
from datetime import datetime

def parse_advising_eml(file_path, semester_id="Spring2026"):
    """
    Parses an .eml file to extract advising slots.
    Returns a dictionary structure suitable for Firestore write:
    {
        "docId": semester_id, # Key for the document
        "semester": semester_id,
        "slots": [ ... ]
    }
    Wait, main.py expects a list of items to write to a collection.
    For Advising, we write ONE document to 'advising_schedules/{semester}'.
    
    So we should return a list containing ONE dict with "docId" set to semester_id.
    """
    
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
            j = i + 1
            credit_range = None
            time_range = None
            
            # Lookahead
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
                             parts = l2.split('-')
                             if len(parts) >= 2:
                                 try:
                                     p1 = re.search(r'(\d+\.?\d*)', parts[0]).group(1)
                                     p2 = re.search(r'(\d+\.?\d*)', parts[1]).group(1)
                                     min_c = float(p1)
                                     max_c = float(p2)
                                 except: pass
                        credit_range = {'min': min_c, 'max': max_c}
                
                # Check Time
                if not time_range and ("M." in l2 or "m." in l2):
                    t_match = time_pattern.search(l2)
                    if t_match:
                        start_str = f"{t_match.group(1)} {t_match.group(2)}"
                        end_str = f"{t_match.group(3)} {t_match.group(4)}"
                        time_range = {'start': start_str, 'end': end_str}
                
                if credit_range and time_range:
                    break
                j += 1
            
            if current_date and credit_range and time_range:
                try:
                    fmt = "%d %B %Y %I:%M %p"
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
                    i = j 
                except Exception as e:
                    print(f"Error parsing date/time: {e}")
        i += 1
    
    # Return as list of 1 item (the schedule doc) to match main.py loop
    return [{
        "docId": semester_id.replace(" ", ""), # "Spring2026"
        "semester": semester_id,
        "slots": slots,
        "uploadedAt": datetime.now() # Firestore will convert or we use SERVER_TIMESTAMP in main
    }]
