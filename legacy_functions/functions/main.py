
import firebase_admin
from firebase_admin import firestore
from firebase_functions import https_fn
import itertools
from datetime import datetime

firebase_admin.initialize_app()

@https_fn.on_call()
def generate_schedules_kickoff(req: https_fn.CallableRequest):
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
        all_sections = []
        for code in course_codes:
            query = db.collection(f"courses_{semester}").where("code", "==", code)
            docs = query.stream()
            all_sections.extend([doc.to_dict() for doc in docs])
        
        valid_sections_by_course = {}
        for section in all_sections:
            if is_section_valid(section, filters):
                code = section.get("code")
                if code not in valid_sections_by_course:
                    valid_sections_by_course[code] = []
                valid_sections_by_course[code].append(section)

        if len(valid_sections_by_course) != len(course_codes):
            missing_courses = set(course_codes) - set(valid_sections_by_course.keys())
            # Optionally, you can return an error or a message about missing courses.
            pass

        all_combinations = list(itertools.product(*valid_sections_by_course.values()))

        final_schedules = []
        for combo in all_combinations:
            if not has_time_conflict(combo):
                final_schedules.append(combo)

        generation_id = db.collection("schedule_generations").document().id
        db.collection("schedule_generations").document(generation_id).set({
            "userId": user_id,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "semester": semester,
            "courses": course_codes,
            "filters": filters,
            "combinations": final_schedules, # Storing the full section data
            "status": "completed",
        })

        return {"generationId": generation_id}

    except Exception as e:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INTERNAL, str(e))

def is_section_valid(section, filters):
    # Capacity Check
    capacity_str = section.get("capacity", "0/0")
    try:
        enrolled, total = map(int, capacity_str.split('/'))
        if total > 0 and enrolled >= total:
            return False
    except (ValueError, IndexError):
        pass # Ignore if capacity is not in the expected format

    # Day Exclusion
    excluded_days = filters.get('exclude_days', [])
    day_map = {'Sat': 'S', 'Sun': 'U', 'Mon': 'M', 'Tue': 'T', 'Wed': 'W', 'Thu': 'R', 'Fri': 'F'}
    excluded_short_days = {day_map.get(day) for day in excluded_days if day_map.get(day)}

    if section.get("sessions"):
        for session in section.get("sessions"):
            session_days = set(session.get("day", "").upper())
            if not session_days.isdisjoint(excluded_short_days):
                return False

    # Faculty Exclusion
    excluded_faculty = filters.get('exclude_faculty', [])
    if excluded_faculty and section.get("sessions"):
        for session in section.get("sessions"):
            faculty = session.get("faculty", "").strip().lower()
            if faculty and any(ex_fac.strip().lower() in faculty for ex_fac in excluded_faculty if ex_fac.strip()):
                return False
    return True

def has_time_conflict(schedule):
    for i in range(len(schedule)):
        for j in range(i + 1, len(schedule)):
            if courses_conflict(schedule[i], schedule[j]):
                return True
    return False

def courses_conflict(course1, course2):
    for s1 in course1.get("sessions", []):
        for s2 in course2.get("sessions", []):
            if s1.get("day") == s2.get("day") and s1.get("startTime") and s2.get("startTime"):
                start1, end1 = parse_time(s1["startTime"]), parse_time(s1["endTime"])
                start2, end2 = parse_time(s2["startTime"]), parse_time(s2["endTime"])
                if start1 and end1 and start2 and end2 and max(start1, start2) < min(end1, end2):
                    return True
    return False

def parse_time(time_str):
    try:
        return datetime.strptime(time_str.strip(), '%I:%M %p')
    except ValueError:
        return None
