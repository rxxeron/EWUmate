from firebase_functions import https_fn
from firebase_admin import firestore
import itertools
from datetime import datetime

def parse_time_to_minutes(time_str):
    """Parses 'HH:mm AM/PM' to minutes from midnight."""
    try:
        dt = datetime.strptime(time_str.upper(), "%I:%M %p")
        return dt.hour * 60 + dt.minute
    except:
        return 0

def do_sessions_overlap(s1, s2):
    """
    Checks if two sessions overlap.
    s1, s2: dict with 'day', 'startTime', 'endTime'.
    """
    if s1['day'] != s2['day']:
        return False
    
    start1 = parse_time_to_minutes(s1['startTime'])
    end1 = parse_time_to_minutes(s1['endTime'])
    start2 = parse_time_to_minutes(s2['startTime'])
    end2 = parse_time_to_minutes(s2['endTime'])
    
    return max(start1, start2) < min(end1, end2)

def is_valid_combination(sections):
    """
    Checks if a list of sections has any timing conflict.
    Each section has a list of 'sessions'.
    """
    all_sessions = []
    for sec in sections:
        all_sessions.extend(sec.get('sessions', []))
        
    for i in range(len(all_sessions)):
        for j in range(i + 1, len(all_sessions)):
            if do_sessions_overlap(all_sessions[i], all_sessions[j]):
                return False
    return True

@https_fn.on_call()
def generate_schedule_combinations(req: https_fn.CallableRequest):
    """
    Generates non-conflicting schedule combinations.
    Input:
        - semester: str (e.g. "Spring2026")
        - courses: List[str] (e.g. ["CSE101", "MAT101"])
    Output:
        - combinations: List[List[SectionParams]]
    """
    data = req.data
    semester = data.get('semester')
    course_codes = data.get('courses', [])
    
    if not semester or not course_codes:
        return {"error": "Missing semester or courses"}

    db = firestore.client()
    
    # --- Validate User History & Current Enrollment ---
    if req.auth and req.auth.uid:
        user_ref = db.collection('users').document(req.auth.uid)
        user_doc = user_ref.get()
        if user_doc.exists:
            user_data = user_doc.to_dict()
            
            # 1. Block Currently Enrolled
            current_enrolled_ids = user_data.get('enrolledSections', [])
            # We need to resolve IDs to Codes to block them?
            # Fetching all enrolled course docs is expensive.
            # But usually `enrolledSections` stores IDs. 
            # If the client sends CODES, we can't easily check IDs without fetching.
            # However, typically "Current" courses are not the main issue for manual entry (user knows what they are taking).
            # But let's check `academicResults` which HAS codes.
            
            # 2. Block Completed (Passed) Courses
            results = user_data.get('academicResults', [])
            blocked_codes = set()
            
            for r in results:
                r_code = r.get('courseCode')
                r_grade = r.get('grade')
                # Rule: Block validation unless Grade is 'F'
                # Meaning: If Passed (Not F), it is Blocked.
                # If F, it is Allowed (Not Blocked).
                if r_code and r_grade != 'F':
                    blocked_codes.add(r_code)
            
            # Filter the requested list
            # course_codes = [c for c in course_codes if c not in blocked_codes]
            
            # User Request: "if a invalid course then it should return for a change first"
            # Return error if any blocked course is found.
            if blocked_codes:
                bad_courses = ", ".join(blocked_codes)
                return {
                    "error": f"You have already passed: {bad_courses}. Please remove them to generate a schedule."
                }
            
            # Note: We are NOT blocking "Current Enrolled" strictly here because resolving IDs to Codes
            # requires extra DB reads. The Frontend filter handles the bulk of it.
            # The Critical user request was "only when the course has f grade", targeting History.
    
    collection_name = f"courses_{semester.replace(' ', '')}"
    
    # 1. Fetch all sections for requested courses
    # Use whereIn (limit 30)
    sections_by_course = {code: [] for code in course_codes}
    
    # Batch if needed, but assuming < 30 courses requested
    docs = db.collection(collection_name).where('code', 'in', course_codes).stream()
    
    for doc in docs:
        d = doc.to_dict()
        
        # Filter out 0 capacity
        cap = d.get('capacity', '0/0')
        if cap == '0/0' or str(cap).endswith('/0'):
            continue

        d['id'] = doc.id
        code = d.get('code')
        if code in sections_by_course:
            sections_by_course[code].append(d)
            
    # 2. Prepare lists for Cartesian Product
    # Remove courses that have no sections found (to avoid empty product)
    valid_courses = [c for c in course_codes if sections_by_course[c]]
    lists_of_sections = [sections_by_course[c] for c in valid_courses]
    
    if not lists_of_sections:
         return {"combinations": []}

    # 3. Generate Combinations
    combinations = []
    # Limit number of Combinations to explore? 
    # If 5 courses * 5 sections each = 3125 combinations. Fast enough.
    
    for combo in itertools.product(*lists_of_sections):
        if is_valid_combination(combo):
            # Format output
            valid_set = []
            for sec in combo:
                valid_set.append({
                    'courseCode': sec.get('code'),
                    'courseName': sec.get('courseName'),
                    'section': sec.get('section'),
                    'faculty': sec.get('faculty'),
                    'id': sec.get('id'),
                    'sessions': sec.get('sessions', []),
                    'capacity': sec.get('capacity', 0),
                    'enrolled': sec.get('enrolled', 0)
                })
            combinations.append(valid_set)
            
            if len(combinations) >= 50: # sensible limit
                break
                
    return {"combinations": combinations}
