import pdfplumber
import re
import json

pdf_path = r"C:\Users\ibnea\Downloads\Mobile App\Mobile App\flutter_v2_new\Updated_Faculty_List_Spring-26.2026-01-15.20-07-05.pdf"
output_path = r"C:\Users\ibnea\Downloads\Mobile App\Mobile App\flutter_v2_new\functions\data\courses_spring2026.json"

# Regex to capturing the start of the line
# format: CSE101 1 ABC 10/40 ...
# Group 1: Code (e.g. CSE101)
# Group 2: Section (e.g. 1)
# Group 3: Faculty (e.g. ABC) - might be 2-4 chars
# Group 4: Capacity (e.g. 10/40)
# Group 5: The rest (Time Day Room)
line_pattern = re.compile(r"^([A-Z]{3}\d{3})\s+(\d+)\s+([A-Z]+)\s+(\d+/\d+)\s+(.*)$")

# Time pattern: 08:30 AM - 10:00 AM
time_pattern = re.compile(r"(\d{1,2}:\d{2}\s*(?:AM|PM)\s*-\s*\d{1,2}:\d{2}\s*(?:AM|PM))")

# Days: S M T W R F A (Combinations like S T, M W)
# We'll try to find the days after the time.

courses = []

with pdfplumber.open(pdf_path) as pdf:
    print(f"Processing {len(pdf.pages)} pages...")
    for page_num, page in enumerate(pdf.pages):
        text = page.extract_text()
        if not text:
            continue
        
        lines = text.split('\n')
        for line in lines:
            match = line_pattern.match(line)
            if match:
                code, section, faculty, capacity, rest = match.groups()
                
                # Parse 'rest' -> Time | Day | Room
                # Strategy: Extract Time first
                time_match = time_pattern.search(rest)
                startTime = ""
                endTime = ""
                day_str = ""
                room = ""
                
                if time_match:
                    full_time = time_match.group(1)
                    # Split time
                    parts = full_time.split('-')
                    if len(parts) == 2:
                        startTime = parts[0].strip()
                        endTime = parts[1].strip()
                    
                    # Logic: Tokens after time. Iterate to find Days, rest is Room.
                    # Valid day tokens: S, M, T, W, R, F, A (and potentially concatenated or commas, but usually space separated in this PDF)
                    valid_days = {'S', 'M', 'T', 'W', 'R', 'F', 'A', 'ST', 'MW', 'SR', 'TR'} 
                    
                    post_time = rest.replace(full_time, "").strip()
                    tokens = post_time.split()
                    
                    day_tokens = []
                    room_tokens = []
                    
                    parsing_days = True
                    for token in tokens:
                        # Check if token is a strictly valid day character or combination
                        # Some formats might be "S,T". Cleaning simple punctuation.
                        clean_token = token.replace(',', '').upper()
                        
                        # Heuristic: If parsing days, and this token looks like a day (single letter or double day char), keep it.
                        # If it looks like a number ("529") or word ("Lab"), switch to room.
                        if parsing_days:
                            if all(c in 'SMTWRFA' for c in clean_token) and len(clean_token) <= 3:
                                day_tokens.append(clean_token)
                            else:
                                parsing_days = False
                                room_tokens.append(token)
                        else:
                            room_tokens.append(token)
                            
                    day_str = " ".join(day_tokens)
                    room = " ".join(room_tokens)
                    
                    # Fallback if no days found but room exists (maybe room started with 'A' or something? Unlikely for EWU rooms)
                    if not day_str and room:
                         # basic check: if room is "Online", day might be TBA
                         pass
                        
                else:
                    # Maybe it's "Online" or "TBA"
                    if "Online" in rest:
                        room = "Online"
                        day_str = "TBA" # or parse day if present
                    else:
                        room = "TBA"
                        day_str = "TBA"

                course_obj = {
                    "id": f"{code}-{section}", # Unique ID concept
                    "courseCode": code,
                    "section": section,
                    "faculty": faculty,
                    "capacity": capacity,
                    "startTime": startTime,
                    "endTime": endTime,
                    "day": day_str,
                    "room": room,
                    "semester": "Spring 2026"
                }
                courses.append(course_obj)

print(f"Extracted {len(courses)} courses.")

# Save to JSON
with open(output_path, 'w') as f:
    json.dump(courses, f, indent=2)

print(f"Saved to {output_path}")
