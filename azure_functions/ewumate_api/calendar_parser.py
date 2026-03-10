import re
import hashlib
import pdfplumber
from datetime import datetime

def parse_calendar_pdf(pdf_file, filename=None, debug=False):
    events = []
    metadata = {
        "currentSemester": None,
        "nextSemester": None,
        "switchDate": None,
        "year": None
    }
    
    def try_parse_date(d_str, y):
        if not d_str or not y: return None
        # Clean string: remove dots, extra spaces
        d_str = d_str.replace('.', '').replace(',', '').strip()
        # Handle "May 12 - 14" -> "May 12"
        d_str = re.split(r'[-–]', d_str)[0].strip()
        
        for fmt in ["%B %d %Y", "%b %d %Y", "%d %B %Y", "%d %b %Y"]:
            try:
                return datetime.strptime(f"{d_str} {y}", fmt)
            except:
                continue
        return None
    
    # regex for header semester
    semester_pattern = re.compile(r"(Spring|Summer|Fall)\s+(\d{4})", re.IGNORECASE)
    reopens_pattern = re.compile(r"University Reopens(?: for)?\s+(Summer|Fall|Spring)\s+(\d{4})", re.IGNORECASE)
    admission_test_pattern = re.compile(r"Admission Test for\s+(Summer|Fall|Spring)\s+(\d{4})", re.IGNORECASE)

    # Date pattern: "January 06" or "Jan 06"
    months = r"(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"
    # Matches "January 06" or "Jan 06-08"
    date_start_pattern = re.compile(rf"^({months})\s+(\d{{1,2}}(?:[-–]\d{{1,2}})?)(.*)", re.IGNORECASE)

    current_year = None

    def cluster_words_into_lines(words, y_tolerance=5):
        # Sort by 'top'
        words = sorted(words, key=lambda w: w['top'])
        lines = []
        if not words: return lines
        
        current_line = [words[0]]
        current_y = words[0]['top']
        
        for w in words[1:]:
            # If w['top'] is close to current_y
            if abs(w['top'] - current_y) <= y_tolerance:
                current_line.append(w)
            else:
                # new line
                lines.append(current_line)
                current_line = [w]
                current_y = w['top']
                
        if current_line:
            lines.append(current_line)
        return lines

    with pdfplumber.open(pdf_file) as pdf:
        page = pdf.pages[0]
        
        # 1. Metadata from Filename (Primary)
        if filename:
            filename_match = semester_pattern.search(filename)
            if filename_match:
                metadata["currentSemester"] = f"{filename_match.group(1)} {filename_match.group(2)}"
                metadata["year"] = filename_match.group(2)
                current_year = metadata["year"]
        
        # 1b. Fallback: Metadata from Header (Searching top of first page)
        all_text = page.extract_text() or ""
        if not metadata["currentSemester"]:
             # Try to get it from object itself if possible (BytesIO might not have it, but just in case)
             fname = str(getattr(pdf_file, 'name', ''))
             if fname:
                 filename_match = semester_pattern.search(fname)
                 if filename_match:
                     metadata["currentSemester"] = f"{filename_match.group(1)} {filename_match.group(2)}"
                     metadata["year"] = filename_match.group(2)
                     current_year = metadata["year"]

        if not metadata["currentSemester"]:
            for line in all_text.split('\n')[:20]: # Check first 20 lines for semester header
                sem_match = semester_pattern.search(line)
                if sem_match and "Admission" not in line and "Reopens" not in line:
                     metadata["currentSemester"] = f"{sem_match.group(1)} {sem_match.group(2)}"
                     metadata["year"] = sem_match.group(2)
                     current_year = metadata["year"]
                     break
        
        # Fallback for year if not in header
        if not current_year:
            year_match = re.search(r"\b(202\d)\b", all_text)
            if year_match:
                current_year = year_match.group(1)
                metadata["year"] = current_year
        
        # 2. Extract Body via Clustering
        # Coordinates
        header_bottom = 120
        footer_top = 780
        
        # Refine footer top by looking for "reserves"
        all_words = page.extract_words()
        for w in all_words:
             if 'University reserves' in w['text'] and w['top'] > 300:
                  footer_top = min(footer_top, w['top'])
        
        body_words = [w for w in all_words if w['bottom'] > header_bottom and w['top'] < footer_top]
        raw_lines = cluster_words_into_lines(body_words, y_tolerance=6) # Slightly looser tolerance
        
        curr_date = ""
        curr_day = ""
        curr_event_parts = []
        
        def finalize(date, day, text_parts):
            if not date or not text_parts: return
            
            # Join with spaces
            full_event = " ".join(text_parts).strip()
            
            # Fix spacing issues if any (double spaces)
            full_event = re.sub(r'\s+', ' ', full_event)
            
            # Metadata Checks
            full_lower = full_event.lower()
            
            # 1. University Reopens (Global Switch Date)
            if "university reopens" in full_lower:
                 # The switch date is for the semester whose calendar is being parsed
                 if not metadata.get("nextSemester"):
                     metadata["nextSemester"] = metadata.get("currentSemester")
                 
                 try:
                     d_str = re.split(r'[-–]', date)[0].strip()
                     dt = try_parse_date(d_str, current_year)
                     if dt:
                         metadata["switchDate"] = dt.strftime("%Y-%m-%d")
                 except: pass
            
            # 2. Submission of Final Grades
            if "submission of final grades" in full_lower:
                try:
                    d_range = re.split(r'[-–]', date)
                    if len(d_range) > 0 and current_year:
                        dt_start = try_parse_date(d_range[0].strip(), current_year)
                        if dt_start:
                            metadata["gradeSubmissionStart"] = dt_start.strftime("%Y-%m-%d")
                            if len(d_range) > 1:
                                end_part = d_range[1].strip()
                                if re.match(r'^\d+$', end_part):
                                    end_part = f"{d_range[0].strip().split(' ')[0]} {end_part}"
                                dt_end = try_parse_date(end_part, current_year)
                                metadata["gradeSubmissionDeadline"] = dt_end.strftime("%Y-%m-%d") if dt_end else dt_start.strftime("%Y-%m-%d")
                            else:
                                metadata["gradeSubmissionDeadline"] = dt_start.strftime("%Y-%m-%d")
                except: pass

            # 3. First Day of Classes (Current vs Next)
            if "first day of classes" in full_lower or "classes begin" in full_lower:
                dt = try_parse_date(date, current_year)
                if dt:
                    # Check if it mentions a specific semester
                    sem_match = semester_pattern.search(full_event)
                    if sem_match:
                        # "First Day of Classes for Summer 2026"
                        metadata["upcomingSemesterStartDate"] = dt.strftime("%Y-%m-%d")
                    else:
                        # Just "First Day of Classes" (Current)
                        metadata["currentSemesterStartDate"] = dt.strftime("%Y-%m-%d")

            # 4. Online Advising
            if "online advising" in full_lower or "advising of courses" in full_lower:
                try:
                    d_range = re.split(r'[-–]', date)
                    if len(d_range) > 0 and current_year:
                        dt_start = try_parse_date(d_range[0].strip(), current_year)
                        if dt_start:
                            metadata["advisingStartDate"] = dt_start.strftime("%Y-%m-%d")
                except: pass

            # 5. Admission Test (Fallback for next semester detection)
            if "admission test" in full_lower and not metadata.get("nextSemester"):
                 match = admission_test_pattern.search(full_event)
                 if match:
                      metadata["nextSemester"] = f"{match.group(1)} {match.group(2)}"
            
            unique_str = f"{metadata.get('currentSemester')}|{date}|{full_event}"
            # etype logic
            etype = "Holiday" if "holiday" in full_event.lower() else "Academic"

            # Standardize event date if possible
            std_date = date
            dt = try_parse_date(date, current_year)
            if dt:
                std_date = dt.strftime("%Y-%m-%d")

            events.append({
                "date": std_date,
                "name": full_event,
                "semester": metadata.get("currentSemester"),
                "type": etype,
            })

        for line_words in raw_lines:
            # Sort words by X
            line_words.sort(key=lambda w: w['x0'])
            
            date_tokens = []
            day_tokens = []
            evt_tokens = []
            
            # Columns
            col1_end = 150
            col2_end = 260
            
            for w in line_words:
                cx = (w['x0'] + w['x1']) / 2
                if cx < col1_end:
                    date_tokens.append(w['text'])
                elif cx < col2_end:
                    day_tokens.append(w['text'])
                else:
                    evt_tokens.append(w['text'])
            
            d_str = " ".join(date_tokens).strip()
            day_str = " ".join(day_tokens).strip()
            evt_str = " ".join(evt_tokens).strip()
            
            # Check if d_str is actually a date
            is_date_line = False
            if d_str:
                if date_start_pattern.match(d_str):
                    is_date_line = True

            if is_date_line:
                # New Event
                if curr_event_parts:
                    finalize(curr_date, curr_day, curr_event_parts)
                    curr_event_parts = []
                
                curr_date = d_str
                curr_day = day_str
                    
                curr_event_parts = [evt_str] if evt_str else []
            else:
                # Continuation or Non-Date line text
                # Append all parts to current event
                text_to_append = []
                if d_str: text_to_append.append(d_str)
                if day_str: text_to_append.append(day_str)
                if evt_str: text_to_append.append(evt_str)
                
                if text_to_append:
                     curr_event_parts.extend(text_to_append)

        # Finalize
        if curr_event_parts:
             finalize(curr_date, curr_day, curr_event_parts)

    return {"events": events, "metadata": metadata}
