import pdfplumber
import json
import re

pdf_path = r"C:\Users\ibnea\Downloads\Mobile App\Mobile App\flutter_v2_new\69424bf19d906466563612 (1).pdf"
output_path = r"C:\Users\ibnea\Downloads\Mobile App\Mobile App\flutter_v2_new\functions\data\calendar_extracted.json"

# Regex for Date: "May 12", "June 20-22", "July 1"
# Matches Month Name followed by numbers
date_pattern = re.compile(r"^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2}(-?\d{1,2})?", re.IGNORECASE)

events = []
current_semester = "Unknown"

with pdfplumber.open(pdf_path) as pdf:
    print(f"Processing {len(pdf.pages)} pages...")
    for page in pdf.pages:
        # Check title only on first page or top of pages
        text = page.extract_text()
        if "Summer 2026" in text:
             current_semester = "Summer 2026"
        elif "Spring 2026" in text:
             current_semester = "Spring 2026"
        elif "Fall 2026" in text:
             current_semester = "Fall 2026"

        text = page.extract_text()
        if not text: continue
        
        # Check title
        if "Summer 2026" in text: current_semester = "Summer 2026"
        elif "Spring 2026" in text: current_semester = "Spring 2026"
        elif "Fall 2026" in text: current_semester = "Fall 2026"

        lines = text.split('\n')
        
        # Parsing State
        current_event = None
        global current_month_context
        current_month_context = ""

        for line in lines:
            line = line.strip()
            if not line: continue
            
            # Regex for Date at START of line
            # Matches: "May 12", "May 20-22", "May 21"
            month_match = re.match(r"^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2}(?:-\d{1,2})?)", line, re.IGNORECASE)
            
            # Helper for "20-22" (implied month)
            # Only matches if line starts with digits and has current_month
            day_only_match = re.match(r"^(\d{1,2}(?:-\d{1,2})?)\s+", line) # Must be followed by space/text

            new_date_found = False
            date_str = ""
            remainder_text = ""
            
            if month_match:
                current_month_context = month_match.group(1)
                date_str = month_match.group(0) # "May 12"
                remainder_text = line[len(date_str):].strip() # Text after date
                new_date_found = True
            elif day_only_match and current_month_context:
                # Be careful: strictly check if it looks like a calendar row.
                # "20  Classes begin" -> OK
                # "2026" -> Year? Ignore.
                day_part = day_only_match.group(1)
                if int(day_part.split('-')[0]) <= 31:
                    date_str = f"{current_month_context} {day_part}"
                    remainder_text = line[len(day_part):].strip()
                    new_date_found = True

            if new_date_found:
                # Save previous event
                if current_event:
                    events.append(current_event)
                
                # Start new event
                # Parse Day? 
                # remainder_text might start with "Tuesday   University opens..."
                # Heuristic: Extract first word if it's a weekday
                # Improved Day Parsing
                # We iteratively consume tokens from start of 'remainder_text'
                # valid tokens: "Sunday", "Mon", "Tue", "-", ",", "to", "&"
                
                day_tokens = []
                event_tokens = remainder_text.split()
                
                valid_day_names = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 
                                   'sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']
                
                valid_separators = ['-', '–', 'to', '&', ',']
                
                idx = 0
                while idx < len(event_tokens):
                    token = event_tokens[idx]
                    clean_token = token.lower().replace(',', '').replace('.', '').replace(';', '')
                    
                    is_day = False
                    # Check if token contains a day name (e.g. "Sunday-Tuesday")
                    # Split by hyphens to check parts
                    sub_parts = re.split(r'[-–]', clean_token)
                    if all((part in valid_day_names or part == '') for part in sub_parts if part):
                        is_day = True
                    
                    if clean_token in valid_day_names or clean_token in valid_separators or is_day:
                        day_tokens.append(token)
                        idx += 1
                    else:
                        break
                        
                day_str = " ".join(day_tokens)
                event_desc = " ".join(event_tokens[idx:])
                
                current_event = {
                    "date": date_str,
                    "day": day_str,
                    "event": event_desc,
                    "semester": current_semester,
                    "type": "CALENDAR_EVENT",
                    "raw_lines": [line]
                }
            else:
                # Continuation line
                if current_event:
                    # Append to description
                    current_event["event"] += " " + line
                    current_event["raw_lines"].append(line)
        
        # Append last event
        if current_event:
            events.append(current_event)

print(f"Extracted {len(events)} events for {current_semester}.")

with open(output_path, 'w') as f:
    json.dump(events, f, indent=2)

print(f"Saved to {output_path}")
