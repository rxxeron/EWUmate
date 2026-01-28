
import email
from email import policy
import re
import json
import os
import sys

# Set up logging to file
log_file = "advising_parse_log.txt"

def log(msg):
    with open(log_file, "a", encoding="utf-8") as f:
        f.write(msg + "\n")
    print(msg)

def parse_advising_eml(file_path):
    log(f"Reading EML file: {file_path}")
    try:
        with open(file_path, 'rb') as f:
            msg = email.message_from_binary_file(f, policy=policy.default)
    except Exception as e:
        log(f"Error opening file: {e}")
        return []
    
    body = ""
    if msg.is_multipart():
        for part in msg.walk():
            contentType = part.get_content_type()
            log(f"Found part: {contentType}")
            if contentType == 'text/plain':
                body = part.get_payload(decode=True).decode('utf-8', errors='ignore')
                log(f"Extracted plain text body, length: {len(body)}")
                break
    else:
        body = msg.get_payload(decode=True).decode('utf-8', errors='ignore')

    if not body:
        log("Could not find plain text body in EML")
        # Try finding html part and converting? No, usually valid EML has text.
        return []

    # Clean up
    body = body.replace('\r', '')
    
    slots = []
    
    # Locate Sections
    undergrad_idx = body.find("*Undergraduate Programs*")
    grad_idx = body.find("*Graduate Programs*")
    
    log(f"Undergraduate start index: {undergrad_idx}")
    log(f"Graduate start index: {grad_idx}")

    def extract_slots_from_text(text, program_type):
        local_slots = []
        lines = [line.strip() for line in text.split('\n') if line.strip()]
        
        i = 0
        while i < len(lines):
            line = lines[i]
            # Pattern: DD Month YYYY (e.g., 03 December 2025)
            # Regex: Start with 2 digits, space, letters, space, 4 digits
            if re.match(r"^\d{2}\s+[A-Za-z]+\s+\d{4}", line):
                date_val = line
                # Look ahead for criteria and time
                # We need to be careful about how many lines ahead.
                # Sometimes there are extra blank lines or tokens.
                
                # Heuristic: Check next few lines for a Time Pattern
                # Time Pattern: 06:00 P.M.- 06:50 P.M.
                time_found = None
                criteria_found = None
                
                # Scan next 5 lines
                for j in range(1, 6):
                    if i + j >= len(lines): break
                    sub_line = lines[i+j]
                    
                    # Check for Time
                    if re.search(r"\d{1,2}:\d{2}.*-.*\d{1,2}:\d{2}", sub_line):
                        time_found = sub_line
                        # The criteria is likely everything between date and time
                        # Usually just one line, but could be multiple if wrapped
                        criteria_lines = lines[i+1 : i+j]
                        criteria_found = " ".join(criteria_lines)
                        
                        # Advance main loop
                        i += j 
                        break
                
                if time_found:
                    local_slots.append({
                        "type": program_type,
                        "date": date_val,
                        "criteria": criteria_found,
                        "time": time_found
                    })
                    log(f"Found Slot: {date_val} | {criteria_found} | {time_found}")
                else:
                    # Maybe it's just a date line without time (header?)
                    pass
            
            i += 1
        return local_slots

    if undergrad_idx != -1:
        end_idx = grad_idx if grad_idx != -1 else len(body)
        u_text = body[undergrad_idx:end_idx]
        slots.extend(extract_slots_from_text(u_text, "Undergraduate"))

    if grad_idx != -1:
        g_text = body[grad_idx:]
        slots.extend(extract_slots_from_text(g_text, "Graduate"))

    return slots

def parse_credits(criteria):
    min_c = 0.0
    max_c = 999.0
    
    # "120.5 Credits & above"
    m_above = re.search(r"(\d+\.?\d*)\s*Credits?\s*&\s*above", criteria, re.IGNORECASE)
    if m_above:
        return float(m_above.group(1)), 999.0
        
    # "115.5-120 Credits"
    m_range = re.search(r"(\d+\.?\d*)\s*-\s*(\d+\.?\d*)", criteria)
    if m_range:
        return float(m_range.group(1)), float(m_range.group(2))
    
    # "0.5-10 Credits"
    m_range2 = re.search(r"(\d+\.?\d*)\s*-\s*(\d+\.?\d*)", criteria)
    if m_range2:
        return float(m_range2.group(1)), float(m_range2.group(2))
        
    # "0 Credit"
    if "0 credit" in criteria.lower():
        return 0.0, 0.5 # approximate "0"
        
    return 0.0, 999.0 # Default fallback? Or maybe 0,0?

def process_slots(slots):
    final = []
    for s in slots:
        min_c, max_c = parse_credits(s['criteria'])
        s['min_credits'] = min_c
        s['max_credits'] = max_c
        
        # Check for departments
        # ECO, PPHS, etc.
        # Regex for all caps words separated by commas
        # Exclude "Credits", "AM", "PM"
        words = re.findall(r"\b[A-Z]{2,}\b", s['criteria'])
        ignored = {'AM', 'PM', 'ST'}
        depts = [w for w in words if w not in ignored]
        s['departments'] = depts
        
        final.append(s)
    return final

if __name__ == "__main__":
    # Ensure we use absolute path based on CWD
    cwd = os.getcwd()
    eml_filename = "Online Advising of Courses for Spring Semester 2026.eml"
    eml_path = os.path.join(cwd, eml_filename)
    json_path = os.path.join(cwd, "advising_slots.json")
    
    if os.path.exists(eml_path):
        log(f"Found EML file at {eml_path}")
        raw_slots = parse_advising_eml(eml_path)
        processed_slots = process_slots(raw_slots)
        
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(processed_slots, f, indent=2)
            
        log(f"Successfully saved {len(processed_slots)} slots to {json_path}")
    else:
        log(f"ERROR: File not found at {eml_path}")

