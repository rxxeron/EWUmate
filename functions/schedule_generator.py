from utils import parse_time_to_minutes, times_conflict, is_day_conflict

def generate_schedules(course_sections_map, filters=None, limit=100):
    """
    Generate valid schedules using backtracking.
    
    Args:
        course_sections_map: Dict { 'CSE101': [section_dict_1, section_dict_2], ... }
        filters: Dict of filters (e.g., exclude_days, free_time_ranges)
        limit: Max number of schedules to return.
        
    Returns:
        List of schedules (each schedule is a list of section dicts).
    """
    if not course_sections_map:
        return []

    # 1. Pre-process and Filter Sections individually
    valid_sections_map = {}
    for code, sections in course_sections_map.items():
        valid_sections = [s for s in sections if is_section_valid(s, filters)]
        if not valid_sections:
            return [] # Constraint unsatisfiable: one course has no valid sections
        valid_sections_map[code] = valid_sections

    # 2. Sort courses based on section count (Fail-First Heuristic)
    # Processing courses with fewer options first helps prune the tree earlier.
    sorted_courses = sorted(valid_sections_map.keys(), key=lambda k: len(valid_sections_map[k]))
    
    results = []

    def backtrack(idx, current_schedule):
        # Base case: Solution found
        if idx == len(sorted_courses):
            results.append(list(current_schedule))
            return

        # Stop if limit reached
        if len(results) >= limit:
            return

        course_code = sorted_courses[idx]
        sections = valid_sections_map[course_code]

        for section in sections:
            # Check Time Conflict with currently selected sections
            if not has_conflict(section, current_schedule):
                current_schedule.append(section)
                backtrack(idx + 1, current_schedule)
                current_schedule.pop() # Backtrack
                
                if len(results) >= limit:
                    return

    backtrack(0, [])
    return results

def is_section_valid(section, filters):
    # Mandatory Capacity Check: Ignore Full or 0/0 sections
    # Request: "overlook means exclude the 0/0 or full sections"
    # So we MUST KEEP THIS CHECK. 
    # Logic: if tot <= 0 (it is 0/0) OR enr >= tot (it is full) -> Return False (Exclude)
    cap_str = section.get('capacity', '0/0')
    try:
        # Format "Enrolled/Total" (e.g. "35/35" or "0/0")
        if not cap_str or '/' not in str(cap_str):
            return False
        enr, tot = map(int, str(cap_str).split('/'))
        if tot <= 0 or enr >= tot:
            return False
    except Exception as e:
        # If capacity string is malformed or missing, we skip for safety
        print(f"Warning: Invalid capacity format '{cap_str}': {e}")
        return False

    if not filters:
        return True

    # Exclude Days
    excluded_days = filters.get('exclude_days', [])
    if excluded_days and section.get('sessions'):
        # Map nice names to chars if needed or just string match
        # Assuming section['sessions'] has 'day' like "S M" or "MW"
        # And excluded_days has ["Friday", "Sunday"]
        # Simplified check:
        for sess in section['sessions']:
            day_str = sess.get('day', '')
            for ex in excluded_days:
                # Naive check: if 'Fri' in 'Friday' matches 'F' in day_str?
                # Need consistent day mapping. Assuming optimized parser gives standard days.
                if _days_overlap(day_str, ex): 
                    return False

    return True

def has_conflict(new_section, current_schedule):
    for existing_section in current_schedule:
        if sections_conflict(new_section, existing_section):
            return True
    return False

def sections_conflict(sec1, sec2):
    # Iterate through all sessions (classes/labs) of both sections
    sections1_sessions = sec1.get('sessions', [])
    sections2_sessions = sec2.get('sessions', [])
    
    if not sections1_sessions or not sections2_sessions:
        # If either section has no sessions, no conflict
        return False
    
    for sess1 in sections1_sessions:
        for sess2 in sections2_sessions:
            # 1. Check Day overlap
            day1 = sess1.get('day', '')
            day2 = sess2.get('day', '')
            
            if not is_day_conflict(day1, day2):
                continue
            
            # 2. Check Time overlap
            start1 = parse_time_to_minutes(sess1.get('startTime'))
            end1 = parse_time_to_minutes(sess1.get('endTime'))
            start2 = parse_time_to_minutes(sess2.get('startTime'))
            end2 = parse_time_to_minutes(sess2.get('endTime'))
            
            if times_conflict(start1, end1, start2, end2):
                return True
                
    return False

def _days_overlap(day_code, excluded_day_name):
    # Mapping for overlap check
    # excluded_day_name e.g. "Friday"
    # day_code e.g. "MWF"
    
    day_map = {
        'sunday': 'S', 'sun': 'S',
        'monday': 'M', 'mon': 'M',
        'tuesday': 'T', 'tue': 'T',
        'wednesday': 'W', 'wed': 'W',
        'thursday': 'R', 'thu': 'R',
        'friday': 'F', 'fri': 'F',
        'saturday': 'A', 'sat': 'A'
    }
    
    ex_char = day_map.get(excluded_day_name.lower())
    if not ex_char: return False
    
    # Check if ex_char is in day_code (assuming day_code is "MTWRFA" style)
    # If parser output is "Sun Tues", this needs more robust logic.
    # Assuming optimized parser returns normalized "S M T W R F A" or compacted.
    return ex_char in day_code.upper()
