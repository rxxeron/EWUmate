import firebase_admin
from firebase_admin import firestore
from firebase_functions import https_fn, firestore_fn, options
from datetime import datetime

# Import optimized modules
from .schedule_generator import generate_schedules, is_section_valid
from .utils import parse_time_to_minutes
from .progress import update_semester_summary

firebase_admin.initialize_app()

@https_fn.on_call(memory=options.MemoryOption.MB_512, timeout_sec=60)
def generate_schedules_kickoff(req: https_fn.CallableRequest):
    """
    HTTP Callable: Generate valid schedules for a given set of courses.
    Request Data:
      - semester: str
      - courses: list of course codes
      - filters: dict (optional)
    """
    semester = req.data.get('semester')
    course_codes = req.data.get('courses')
    filters = req.data.get('filters', {})
    user_id = req.auth.uid if req.auth else None

    if not all([semester, course_codes, user_id]):
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            "Missing required parameters: semester, courses, or user ID."
        )

    db = firestore.client()

    try:
        # 1. Fetch Sections for all courses
        course_sections_map = {}
        for code in course_codes:
            # Assuming collection name format 'courses_Spring2026' etc.
            # Ideally sanitized.
            coll_name = f"courses_{semester.replace(' ', '')}" 
            
            # Query for exact code match
            query = db.collection(coll_name).where("code", "==", code)
            docs = query.stream()
            
            sections = [doc.to_dict() for doc in docs]
            if not sections:
                # If no sections found for a course, we can't generate a schedule including it
                # We could return error or just empty list
                return {"generationId": None, "error": f"No sections found for {code}"}
            
            course_sections_map[code] = sections

        # 2. Generate Schedules (Optimized Backtracking)
        # 100 limit to prevent timeout/high memory
        final_schedules = generate_schedules(course_sections_map, filters, limit=100)

        # 3. Store Results
        generation_id = db.collection("schedule_generations").document().id
        db.collection("schedule_generations").document(generation_id).set({
            "userId": user_id,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "semester": semester,
            "courses": course_codes,
            "filters": filters,
            "combinations": final_schedules,
            "status": "completed",
            "count": len(final_schedules)
        })

        return {"generationId": generation_id, "count": len(final_schedules)}

    except Exception as e:
        print(f"Error generating schedules: {e}")
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INTERNAL, str(e))


@firestore_fn.on_document_updated(
    document="users/{userId}",
    region="us-central1",
    memory=options.MemoryOption.MB_256
)
def on_enrollment_change(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Trigger: When user 'enrolledSections' changes, update their weekly schedule.
    """
    before = event.data.before.to_dict() if event.data.before else {}
    after = event.data.after.to_dict() if event.data.after else {}

    old_sections = set(before.get('enrolledSections', []))
    new_sections = set(after.get('enrolledSections', []))

    if old_sections == new_sections:
        return

    user_id = event.params["userId"]
    print(f"Updating schedule for user {user_id} due to enrollment change.")
    
    db = firestore.client()
    
    # helper to get semester
    try:
        config = db.collection('config').document('app_info').get().to_dict()
        current_semester = config.get('currentSemester', '').replace(' ', '')
    except:
        return

    if not current_semester:
        return

    _update_user_weekly_schedule(db, user_id, current_semester, new_sections)


def _update_user_weekly_schedule(db, user_id, semester_id, range_section_ids):
    """
    Fetch section details and overwrite users/{userId}/schedule/{semesterId}
    """
    if not range_section_ids:
        # Clear schedule
        db.collection("users").document(user_id).collection("schedule").document(semester_id).set({
            "weeklyTemplate": _empty_week(),
            "lastUpdated": firestore.SERVER_TIMESTAMP
        })
        return

    # Fetch details
    # This might be optimized by using 'in' query in batches of 10
    # For now, simple loop or batch logic (up to 30 usually fine for 'in' but Firestore limit is 30)
    
    section_ids_list = list(range_section_ids)
    # Breaking into chunks of 30 if needed, but assuming students don't have > 30 sections
    
    course_coll = db.collection(f"courses_{semester_id}")
    
    # We can try fetching by IDs
    # references = [course_coll.document(sid) for sid in section_ids_list]
    # docs = db.get_all(references) # faster than loop
    
    # Since get_all accepts refs...
    refs = [course_coll.document(sid) for sid in section_ids_list]
    docs = db.get_all(refs)

    weekly_template = _empty_week()
    
    for doc in docs:
        if not doc.exists: continue
        data = doc.to_dict()
        
        code = data.get('code', '')
        name = data.get('courseName', '')
        sessions = data.get('sessions', [])
        for sess in sessions:
            days_str = sess.get('day', '').upper()
            found_days = _parse_days(days_str)
            
            for d in found_days:
                weekly_template[d].append({
                    "courseCode": code,
                    "courseName": name, # Added back
                    "startTime": sess.get('startTime'),
                    "endTime": sess.get('endTime'),
                    "room": sess.get('room', 'TBA'),
                    "type": sess.get('type', 'Theory'),
                    "faculty": sess.get('faculty', '')
                })

    # Sort
    for d in weekly_template:
        weekly_template[d].sort(key=lambda x: parse_time_to_minutes(x['startTime']) or 0)

    # Fetch holidays/swaps to maintain parity
    holidays = []
    day_swaps = []
    try:
        calendar_ref = db.collection(f"calendar_{semester_id}")
        for event_doc in calendar_ref.stream():
            evt = event_doc.to_dict()
            title = evt.get('title', '').lower()
            date_str = evt.get('date', '')
            if "holiday" in title:
                holidays.append({"date": date_str, "name": evt.get('title', 'Holiday')})
            swap_match = re.search(r"regular\s+(sunday|monday|tuesday|wednesday|thursday|friday|saturday)\s+class", title)
            if swap_match:
                day_swaps.append({"date": date_str, "actsAs": swap_match.group(1).capitalize(), "reason": evt.get('title', "")})
    except:
        pass

    db.collection("users").document(user_id).collection("schedule").document(semester_id).set({
        "weeklyTemplate": weekly_template,
        "holidays": holidays,
        "daySwaps": day_swaps,
        "lastUpdated": firestore.SERVER_TIMESTAMP
    })

def _empty_week():
    return {k: [] for k in ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]}

def _parse_days(day_str):
    """Legacy-compatible day parser."""
    day_map = {
        "S": "Sunday", "SU": "Sunday", "SUN": "Sunday",
        "M": "Monday", "MO": "Monday", "MON": "Monday",
        "T": "Tuesday", "TU": "Tuesday", "TUE": "Tuesday",
        "W": "Wednesday", "WE": "Wednesday", "WED": "Wednesday",
        "R": "Thursday", "TH": "Thursday", "THU": "Thursday",
        "F": "Friday", "FR": "Friday", "FRI": "Friday",
        "A": "Saturday", "SA": "Saturday", "SAT": "Saturday"
    }
    days = set()
    s = day_str.upper().strip()
    # Check for longest abbreviations first
    sorted_abbrs = sorted(day_map.keys(), key=len, reverse=True)
    
    i = 0
    while i < len(s):
        match = False
        for abbr in sorted_abbrs:
            if s[i:].startswith(abbr):
                days.add(day_map[abbr])
                i += len(abbr)
                match = True
                break
        if not match:
            i += 1
    return list(days)


@firestore_fn.on_document_written(
    document="users/{userId}/semesterProgress/{semesterId}/courses/{courseId}",
    region="us-central1",
    memory=options.MemoryOption.MB_256
)
def on_course_marks_change(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Trigger: When course marks or distribution change, recalculate semester summary.
    """
    user_id = event.params["userId"]
    semester_id = event.params["semesterId"]
    
    db = firestore.client()
    print(f"Recalculating semester progress for user {user_id}, semester {semester_id}.")
    
    try:
        update_semester_summary(db, user_id, semester_id)
    except Exception as e:
        print(f"Error updating semester summary: {e}")
