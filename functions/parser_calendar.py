import re

def parse_calendar_pdf(pdf_path, semester_id):
    import pdfplumber
    events = []
    current_month_context = ""
    
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            if not text: continue
            
            lines = text.split('\n')
            current_event = None
            
            for line in lines:
                line = line.strip()
                if not line: continue
                
                # Regex for Date: "May 12", "May 20-22"
                month_match = re.match(r"^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2}(?:-\d{1,2})?)", line, re.IGNORECASE)
                day_only_match = re.match(r"^(\d{1,2}(?:-\d{1,2})?)\s+", line)

                new_date_found = False
                date_str = ""
                remainder_text = ""
                
                if month_match:
                    current_month_context = month_match.group(1)
                    date_str = month_match.group(0)
                    remainder_text = line[len(date_str):].strip()
                    new_date_found = True
                elif day_only_match and current_month_context:
                    day_part = day_only_match.group(1)
                    # Simple check if valid day number
                    try:
                        if int(day_part.split('-')[0]) <= 31:
                            date_str = f"{current_month_context} {day_part}"
                            remainder_text = line[len(day_part):].strip()
                            new_date_found = True
                    except: pass

                if new_date_found:
                    if current_event:
                        import hashlib
                        unique_str = f"{current_event['semester']}{current_event['date']}{current_event['event']}"
                        event_hash = hashlib.md5(unique_str.encode()).hexdigest()[:10]
                        current_event['docId'] = f"event_{event_hash}"
                        events.append(current_event)
                    
                    # Parse Day Token
                    day_tokens = []
                    event_tokens = remainder_text.split()
                    valid_day_names = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']
                    valid_separators = ['-', '–', 'to', '&', ',']
                    
                    idx = 0
                    while idx < len(event_tokens):
                        token = event_tokens[idx]
                        clean_token = token.lower().replace(',', '').replace('.', '').replace(';', '')
                        is_day = False
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
                        "semester": semester_id,
                        "type": "CALENDAR_EVENT",

                    }
                else:
                    if current_event:
                        current_event["event"] += " " + line
            
            if current_event:
                import hashlib
                unique_str = f"{current_event['semester']}{current_event['date']}{current_event['event']}"
                event_hash = hashlib.md5(unique_str.encode()).hexdigest()[:10]
                current_event['docId'] = f"event_{event_hash}"
                events.append(current_event)
            
    return events
