import re
import hashlib
import pdfplumber

def parse_calendar_pdf(pdf_path, semester_id, debug=False):
    events = []
    
    # Improved Regex for Date:
    # Captures "Jan 12", "January 12", "Jan 12-14", "Jan 12, 14"
    # Case insensitive
    month_regex = r"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*"
    date_regex = r"\d{1,2}(?:[-–,]\d{1,2})*" 
    full_date_pattern = re.compile(rf"^({month_regex})\s+({date_regex})", re.IGNORECASE)
    
    # Regex for just a date number at start of line (continuation of month)
    # e.g. "15" or "15-16"
    day_only_pattern = re.compile(r"^(\d{1,2}(?:[-–]\d{1,2})?)\s+")

    current_month_context = ""
    current_event = None

    def finalize_event(evt):
        if not evt: return
        # Generate ID based on deterministic content
        unique_str = f"{evt['semester']}|{evt['date']}|{evt['event'].strip()}"
        event_hash = hashlib.md5(unique_str.encode()).hexdigest()[:12]
        evt['docId'] = f"event_{event_hash}"
        evt['event'] = evt['event'].strip() # Clean cleanup
        events.append(evt)
        if debug:
            print(f"[DEBUG] Finalized event: {evt['date']} - {evt['event'][:30]}...")

    with pdfplumber.open(pdf_path) as pdf:
        for page_num, page in enumerate(pdf.pages):
            text = page.extract_text()
            if not text: continue
            
            lines = text.split('\n')
            if debug:
                print(f"[DEBUG] Page {page_num+1} - {len(lines)} lines found.")
            
            for line in lines:
                line = line.strip()
                if not line: continue
                
                # Try to detect a new date line
                match_full = full_date_pattern.match(line)
                match_day = day_only_pattern.match(line)
                
                new_date_found = False
                date_str = ""
                remainder_text = ""
                
                if match_full:
                    current_month_context = match_full.group(1) # e.g. "May"
                    date_part = match_full.group(0) # e.g. "May 12"
                    date_str = date_part
                    remainder_text = line[len(date_part):].strip()
                    new_date_found = True
                    if debug:
                        print(f"[DEBUG] Match Full Date: {date_str}")
                    
                elif match_day and current_month_context:
                    # heuristic: only treat as date if it's a small number
                    day_part = match_day.group(1)
                    try:
                        first_num = int(re.split(r'[-–]', day_part)[0])
                        if 1 <= first_num <= 31:
                            date_str = f"{current_month_context} {day_part}"
                            remainder_text = line[len(day_part):].strip()
                            new_date_found = True
                            if debug:
                                print(f"[DEBUG] Match Day Only: {date_str} (Context: {current_month_context})")
                    except:
                        pass

                if new_date_found:
                    # Close previous event
                    if current_event:
                        finalize_event(current_event)
                        current_event = None
                    
                    # Parse Day of Week from the START of remainder tokens
                    # Usually "Sunday Event Description" or "Sun-Mon Orientation"
                    tokens = remainder_text.split()
                    day_tokens = []
                    
                    # Day heuristics
                    valid_days = {'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 
                                  'sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'}
                    
                    idx = 0
                    while idx < len(tokens):
                        tok_clean = tokens[idx].lower().replace(',', '').replace(';', '')
                        # Check "Sun" or "Sun-Mon"
                        is_day_like = False
                        parts = re.split(r'[-–]', tok_clean)
                        if all(p in valid_days for p in parts if p):
                            is_day_like = True
                        
                        # Also skip connectors like "to" if they are between days? 
                        # simplicity: just grab if it looks like a day
                        if is_day_like:
                            day_tokens.append(tokens[idx])
                            idx += 1
                        else:
                            # Stop at first non-day token
                            break
                    
                    day_str = " ".join(day_tokens)
                    event_desc = " ".join(tokens[idx:])
                    
                    current_event = {
                        "date": date_str,
                        "day": day_str,
                        "event": event_desc,
                        "semester": semester_id,
                        "type": "CALENDAR_EVENT"
                    }
                
                else:
                    # Continuation of previous event
                    if current_event:
                        current_event["event"] += " " + line
            
    # Finalize last event
    if current_event:
        finalize_event(current_event)
            
    return events
