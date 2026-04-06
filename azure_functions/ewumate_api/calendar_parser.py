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
    months = r"(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"
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
        
    def expand_date_range(d_str, y):
        """
        Handles "May 12-14" -> ["May 12", "May 13", "May 14"]
        Handles "June 30-July 02" -> ["June 30", "July 01", "July 02"]
        """
        d_str = d_str.replace('.', '').replace(',', '').strip()
        # Now group(1) = month, group(2) = start_day, group(3) = optional end_month, group(4) = end_day
        match = re.match(rf"^({months})\s+(\d{{1,2}})(?:[-–]| to )({months}\s+)?(\d{{1,2}})$", d_str, re.IGNORECASE)
        
        if not match:
            return [d_str]
        
        start_month = match.group(1)
        start_day = int(match.group(2))
        end_month = match.group(3).strip() if match.group(3) else start_month
        end_day = int(match.group(4))
        
        try:
            from datetime import timedelta
            start_dt = try_parse_date(f"{start_month} {start_day}", y)
            end_dt = try_parse_date(f"{end_month} {end_day}", y)
            
            if not start_dt or not end_dt:
                return [d_str]
            
            # Simple iteration to get all days in between
            date_list = []
            curr = start_dt
            while curr <= end_dt:
                date_list.append(curr.strftime("%B %d"))
                curr += timedelta(days=1)
            return date_list
        except:
            return [d_str]

    def finalize(date, day, text_parts):
        if not date or not text_parts: return
        
        full_event = " ".join(text_parts).strip()
        full_event = re.sub(r'\s+', ' ', full_event)
        full_lower = full_event.lower()
        
        # Metadata Checks
        
        # 1. University Reopens (Global Switch Date)
        if "university reopens" in full_lower:
             if not metadata.get("nextSemester"):
                 metadata["nextSemester"] = metadata.get("currentSemester")
             
             try:
                 d_first = re.split(r'[-–]| to ', date)[0].strip()
                 dt = try_parse_date(d_first, current_year)
                 if dt:
                     metadata["switchDate"] = dt.strftime("%Y-%m-%d")
             except: pass
        
        # 2. Grade Submission
        if "grade submission" in full_lower or "submission of final grade" in full_lower:
            try:
                d_range = re.split(r'[-–]| to ', date)
                if len(d_range) > 0 and current_year:
                    dt_start = try_parse_date(d_range[0].strip(), current_year)
                    if dt_start:
                        metadata["gradeSubmissionStart"] = f"{dt_start.strftime('%Y-%m-%d')}T00:00:00+06:00"
                        if len(d_range) > 1:
                            end_part = d_range[1].strip()
                            # Handle relative day like "May 12-14" (14 is end_part)
                            if re.match(r'^\d+$', end_part):
                                month_part = d_range[0].strip().split(' ')[0]
                                end_part = f"{month_part} {end_part}"
                            dt_end = try_parse_date(end_part, current_year)
                            metadata["gradeSubmissionDeadline"] = f"{dt_end.strftime('%Y-%m-%d')}T00:00:00+06:00" if dt_end else metadata["gradeSubmissionStart"]
                        else:
                            metadata["gradeSubmissionDeadline"] = metadata["gradeSubmissionStart"]
            except: pass

        # 3. First Day of Classes
        if "first day of classes" in full_lower or "classes begin" in full_lower:
            d_first = re.split(r'[-–]| to ', date)[0].strip()
            dt = try_parse_date(d_first, current_year)
            if dt:
                bdt_date = f"{dt.strftime('%Y-%m-%d')}T00:00:00+06:00"
                sem_match = semester_pattern.search(full_event)
                if sem_match:
                    metadata["upcomingSemesterStartDate"] = bdt_date
                else:
                    metadata["currentSemesterStartDate"] = bdt_date

        # 4. Advising
        if any(k in full_lower for k in ["online advising", "advising of courses", "advising for"]):
            try:
                d_range = re.split(r'[-–]| to ', date)
                if len(d_range) > 0 and current_year:
                    dt_start = try_parse_date(d_range[0].strip(), current_year)
                    if dt_start:
                        metadata["advisingStartDate"] = f"{dt_start.strftime('%Y-%m-%d')}T00:00:00+06:00"
                        if len(d_range) > 1:
                            end_part = d_range[1].strip()
                            if re.match(r'^\d+$', end_part):
                                month_part = d_range[0].strip().split(' ')[0]
                                end_part = f"{month_part} {end_part}"
                            dt_end = try_parse_date(end_part, current_year)
                            if dt_end:
                                metadata["advisingEndDate"] = f"{dt_end.strftime('%Y-%m-%d')}T00:00:00+06:00"
                            else:
                                metadata["advisingEndDate"] = metadata["advisingStartDate"]
                        else:
                            metadata["advisingEndDate"] = metadata["advisingStartDate"]
                            
                        sem_match = semester_pattern.search(full_event)
                        if sem_match:
                            metadata["nextSemester"] = f"{sem_match.group(1).capitalize()} {sem_match.group(2)}"
            except: pass

        # 5. University Reopens
        if "university reopens" in full_lower:
            d_first = re.split(r'[-–]| to ', date)[0].strip()
            dt = try_parse_date(d_first, current_year)
            if dt:
                bdt_date = f"{dt.strftime('%Y-%m-%d')}T00:00:00+06:00"
                reopen_match = re.search(r"University Reopens for\s+(Spring|Summer|Fall)\s+(\d{4})", full_event, re.IGNORECASE)
                if reopen_match:
                    metadata["nextSemester"] = f"{reopen_match.group(1).capitalize()} {reopen_match.group(2)}"
                    metadata["switchDate"] = bdt_date
                    metadata["upcomingSemesterStartDate"] = bdt_date
                elif not metadata.get("switchDate"):
                    metadata["switchDate"] = bdt_date

        # 6. Final Examination
        if "final examination" in full_lower or "final exam" in full_lower:
            try:
                d_range = re.split(r'[-–]| to ', date)
                if len(d_range) > 0 and current_year:
                    dt_start = try_parse_date(d_range[0].strip(), current_year)
                    if dt_start:
                        metadata["finalExamStart"] = f"{dt_start.strftime('%Y-%m-%d')}T00:00:00+06:00"
                        if len(d_range) > 1:
                            end_part = d_range[1].strip()
                            if re.match(r'^\d+$', end_part):
                                month_part = d_range[0].strip().split(' ')[0]
                                end_part = f"{month_part} {end_part}"
                            dt_end = try_parse_date(end_part, current_year)
                            metadata["finalExamEnd"] = f"{dt_end.strftime('%Y-%m-%d')}T00:00:00+06:00" if dt_end else metadata["finalExamStart"]
                        else:
                            metadata["finalExamEnd"] = metadata["finalExamStart"]
            except: pass

        # 7. Admission Test
        if "admission test" in full_lower and not metadata.get("nextSemester"):
             match = admission_test_pattern.search(full_event)
             if match:
                  metadata["nextSemester"] = f"{match.group(1).capitalize()} {match.group(2)}"
        
        # EXPAND DATE RANGE FOR INDIVIDUAL EVENTS
        is_holiday = "holiday" in full_lower or "semester break" in full_lower or "break" in full_lower
        etype = "Holiday" if is_holiday else "Academic"
        expanded_dates = expand_date_range(date, current_year)
        
        for d_item in expanded_dates:
            std_date = d_item
            dt = try_parse_date(d_item, current_year)
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
