
import email
from email import policy
import re
import json
import os
import sys

def run():
    filename = "Online Advising of Courses for Spring Semester 2026.eml"
    print(f"Looking for: {filename}")
    
    if not os.path.exists(filename):
        print("ERROR: File not found!")
        # Try listing dir
        print("Files in cwd:")
        for f in os.listdir('.'):
            print(f" - {f}")
        return

    print("File found. Parsing...")
    try:
        with open(filename, 'rb') as f:
            msg = email.message_from_binary_file(f, policy=policy.default)
        print("Email parsed.")
    except Exception as e:
        print(f"Exception parsing email: {e}")
        return

    body = None
    if msg.is_multipart():
        for part in msg.walk():
            ct = part.get_content_type()
            print(f"Part: {ct}")
            if ct == 'text/plain':
                body = part.get_payload(decode=True).decode('utf-8', errors='ignore')
                break
    else:
        body = msg.get_payload(decode=True).decode('utf-8', errors='ignore')

    if not body:
        print("No body found.")
        return

    print(f"Body length: {len(body)}")
    
    # regex test
    slots = []
    lines = body.split('\n')
    print(f"Total lines: {len(lines)}")
    
    undergrad_found = False
    
    for i, line in enumerate(lines):
        line = line.strip()
        if "Undergraduate Programs" in line:
            undergrad_found = True
            print(f"Found Undergrad section at line {i}")
        
        # simple date check
        # 03 December 2025
        if re.search(r"\d{2}\s+[A-Za-z]+\s+\d{4}", line):
            print(f"Potential Date line {i}: {line}")
            # check next lines for time
            for j in range(1, 6):
                if i+j < len(lines):
                    sub = lines[i+j].strip()
                    if re.search(r":\d{2}", sub):
                        print(f"  -> Found time match nearby: {sub}")
                        slots.append({"date": line, "time": sub, "criteria": lines[i+1:i+j]})
                        break

    print(f"Total potential slots found: {len(slots)}")
    
    output_file = "advising_slots_debug.json"
    with open(output_file, 'w') as f:
        json.dump(slots, f, indent=2)
    print(f"Saved to {output_file}")

if __name__ == '__main__':
    run()
