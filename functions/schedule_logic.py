"""
Cloud Function: Personalized Schedule Generation
Trigger: Firestore Document Write on user's enrolled courses
Output: Schedule document with weekly template, holidays, and day swaps
"""
from firebase_functions import firestore_fn, options
from firebase_admin import firestore
import re
from datetime import datetime


def _get_admin_secret():
    """Fetch admin secret from Firestore config/admin document."""
    db = firestore.client()
    doc = db.collection('config').document('admin').get()
    if doc.exists:
        return doc.to_dict().get('secret_key', '')
    return ''


@firestore_fn.on_document_written(
    document="users/{userId}/semesterProgress/{semesterId}",
    region="us-central1",
    memory=options.MemoryOption.MB_256
)
def generate_user_schedule(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Triggers when a user's semester progress document changes.
    Generates personalized weekly schedule + holidays + day swaps.
    """
    user_id = event.params["userId"]
    semester_id = event.params["semesterId"]
    
    # Don't trigger on deletes
    if not event.data.after:
        return
        
    db = firestore.client()
    
    # 1. Get enrolled courses from semesterProgress/courses subcollection
    courses_ref = db.collection("users").document(user_id).collection("semesterProgress").document(semester_id).collection("courses")
    enrolled_docs = courses_ref.stream()
    
    enrolled_codes = set()
    for doc in enrolled_docs:
        data = doc.to_dict()
        code = data.get("courseCode", doc.id)
        enrolled_codes.add(code.upper())
    
    if not enrolled_codes:
        print(f"No enrolled courses for {user_id}/{semester_id}")
        return
    
    # 2. Fetch course details from master collection
    # Normalize semester_id to collection name format (e.g., "Spring 2026" -> "Spring2026")
    collection_name = f"courses_{semester_id.replace(' ', '')}"
    
    master_courses_ref = db.collection(collection_name)
    all_courses = master_courses_ref.stream()
    
    # Build weekly template
    weekly_template = {
        "Sunday": [],
        "Monday": [],
        "Tuesday": [],
        "Wednesday": [],
        "Thursday": [],
        "Friday": [],
        "Saturday": []
    }
    
    day_map = {
        "S": "Sunday", "SU": "Sunday", "SUN": "Sunday",
        "M": "Monday", "MO": "Monday", "MON": "Monday",
        "T": "Tuesday", "TU": "Tuesday", "TUE": "Tuesday",
        "W": "Wednesday", "WE": "Wednesday", "WED": "Wednesday",
        "R": "Thursday", "TH": "Thursday", "THU": "Thursday",
        "F": "Friday", "FR": "Friday", "FRI": "Friday",
        "A": "Saturday", "SA": "Saturday", "SAT": "Saturday"
    }
    
    # 1.5 Fetch 'enrolledSections' for precise filtering
    user_doc = db.collection("users").document(user_id).get()
    enrolled_section_ids = set()
    if user_doc.exists:
        u_data = user_doc.to_dict()
        sections = u_data.get("enrolledSections", [])
        if sections and isinstance(sections, list):
            enrolled_section_ids.update(sections)
            print(f"User {user_id} has specific sections: {enrolled_section_ids}")

    # ...
    
    for course_doc in all_courses:
        course_data = course_doc.to_dict()
        code = course_data.get("code", "").upper()
        
        # LOGIC CHANGE: Priority Check
        if enrolled_section_ids:
            # If user has specific sections, ONLY allow exact ID match
            if course_doc.id not in enrolled_section_ids:
                continue
        else:
            # Fallback (old behavior): Match by Code only
            if code not in enrolled_codes:
                continue
        
        sessions = course_data.get("sessions", [])
        for session in sessions:
            day_str = session.get("day", "").upper().strip()
            start_time = session.get("startTime", "")
            end_time = session.get("endTime", "")
            room = session.get("room", "TBA")
            session_type = session.get("type", "Theory")
            faculty = session.get("faculty", "")
            
            # Parse day(s) - could be "MW" or "T R" or "Sunday"
            days_found = _parse_days(day_str, day_map)
            
            for day_name in days_found:
                weekly_template[day_name].append({
                    "courseCode": code,
                    "courseName": course_data.get("courseName", ""),
                    "startTime": start_time,
                    "endTime": end_time,
                    "room": room,
                    "type": session_type,
                    "faculty": faculty
                })
    
    # Sort each day by start time
    for day in weekly_template:
        weekly_template[day].sort(key=lambda x: _time_to_minutes(x.get("startTime", "")))
    
    # 3. Fetch holidays and day swaps from calendar
    calendar_name = f"calendar_{semester_id.replace(' ', '')}"
    calendar_ref = db.collection(calendar_name)
    events = calendar_ref.stream()
    
    holidays = []
    day_swaps = []
    
    for event_doc in events:
        event_data = event_doc.to_dict()
        title = event_data.get("title", "").lower()
        date_str = event_data.get("date", "")
        
        # Detect holidays
        if "holiday" in title:
            holidays.append({
                "date": date_str,
                "name": event_data.get("title", "Holiday")
            })
        
        # Detect day swaps like "Regular Tuesday Classes"
        swap_match = re.search(r"regular\s+(sunday|monday|tuesday|wednesday|thursday|friday|saturday)\s+class", title)
        if swap_match:
            acts_as = swap_match.group(1).capitalize()
            day_swaps.append({
                "date": date_str,
                "actsAs": acts_as,
                "reason": event_data.get("title", "")
            })
    
    # 4. Write schedule document
    schedule_ref = db.collection("users").document(user_id).collection("schedule").document(semester_id)
    schedule_ref.set({
        "weeklyTemplate": weekly_template,
        "holidays": holidays,
        "daySwaps": day_swaps,
        "lastUpdated": firestore.SERVER_TIMESTAMP
    })
    
    print(f"Generated schedule for {user_id}/{semester_id}: {len(enrolled_codes)} courses")


@firestore_fn.on_document_updated(
    document="users/{userId}",
    region="us-central1",
    memory=options.MemoryOption.MB_256
)
def on_enrollment_change(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Triggers when a user document is updated.
    If 'enrolledSections' changed, regenerate their schedule.
    """
    before = event.data.before.to_dict() if event.data.before else {}
    after = event.data.after.to_dict() if event.data.after else {}
    
    old_sections = set(before.get('enrolledSections', []))
    new_sections = set(after.get('enrolledSections', []))
    
    # Only proceed if enrolledSections actually changed
    if old_sections == new_sections:
        return
    
    user_id = event.params["userId"]
    print(f"[on_enrollment_change] User {user_id}: sections changed from {len(old_sections)} to {len(new_sections)}")
    
    db = firestore.client()
    
    # Determine current semester from config
    try:
        config_doc = db.collection('config').document('app_info').get()
        if config_doc.exists:
            semester_id = config_doc.to_dict().get('currentSemester', '')
        else:
            semester_id = ''
    except:
        semester_id = ''
    
    if not semester_id:
        print(f"No current semester configured, skipping schedule generation")
        return
    
    semester_id = semester_id.replace(' ', '')
    
    # Generate schedule directly based on enrolledSections
    _generate_schedule_for_user(db, user_id, semester_id, new_sections)


def _generate_schedule_for_user(db, user_id: str, semester_id: str, enrolled_section_ids: set) -> None:
    """
    Generates schedule for a user based on their enrolled section IDs.
    """
    if not enrolled_section_ids:
        # Clear schedule if no sections enrolled
        schedule_ref = db.collection("users").document(user_id).collection("schedule").document(semester_id)
        schedule_ref.set({
            "weeklyTemplate": {"Sunday": [], "Monday": [], "Tuesday": [], "Wednesday": [], "Thursday": [], "Friday": [], "Saturday": []},
            "holidays": [],
            "daySwaps": [],
            "lastUpdated": firestore.SERVER_TIMESTAMP
        })
        print(f"Cleared schedule for {user_id}/{semester_id}")
        return
    
    # Fetch course details
    collection_name = f"courses_{semester_id}"
    master_courses_ref = db.collection(collection_name)
    
    weekly_template = {
        "Sunday": [], "Monday": [], "Tuesday": [], "Wednesday": [],
        "Thursday": [], "Friday": [], "Saturday": []
    }
    
    day_map = {
        "S": "Sunday", "SU": "Sunday", "SUN": "Sunday",
        "M": "Monday", "MO": "Monday", "MON": "Monday",
        "T": "Tuesday", "TU": "Tuesday", "TUE": "Tuesday",
        "W": "Wednesday", "WE": "Wednesday", "WED": "Wednesday",
        "R": "Thursday", "TH": "Thursday", "THU": "Thursday",
        "F": "Friday", "FR": "Friday", "FRI": "Friday",
        "A": "Saturday", "SA": "Saturday", "SAT": "Saturday"
    }
    
    for section_id in enrolled_section_ids:
        try:
            course_doc = master_courses_ref.document(section_id).get()
            if not course_doc.exists:
                continue
            
            course_data = course_doc.to_dict()
            code = course_data.get("code", "").upper()
            sessions = course_data.get("sessions", [])
            
            for session in sessions:
                day_str = session.get("day", "").upper().strip()
                days_found = _parse_days(day_str, day_map)
                
                for day_name in days_found:
                    weekly_template[day_name].append({
                        "courseCode": code,
                        "courseName": course_data.get("courseName", ""),
                        "startTime": session.get("startTime", ""),
                        "endTime": session.get("endTime", ""),
                        "room": session.get("room", "TBA"),
                        "type": session.get("type", "Theory"),
                        "faculty": session.get("faculty", "")
                    })
        except Exception as e:
            print(f"Error fetching section {section_id}: {e}")
    
    # Sort each day by start time
    for day in weekly_template:
        weekly_template[day].sort(key=lambda x: _time_to_minutes(x.get("startTime", "")))
    
    # Fetch holidays
    calendar_name = f"calendar_{semester_id}"
    calendar_ref = db.collection(calendar_name)
    
    holidays = []
    day_swaps = []
    
    try:
        for event_doc in calendar_ref.stream():
            event_data = event_doc.to_dict()
            title = event_data.get("title", "").lower()
            date_str = event_data.get("date", "")
            
            if "holiday" in title:
                holidays.append({"date": date_str, "name": event_data.get("title", "Holiday")})
            
            import re
            swap_match = re.search(r"regular\s+(sunday|monday|tuesday|wednesday|thursday|friday|saturday)\s+class", title)
            if swap_match:
                day_swaps.append({
                    "date": date_str,
                    "actsAs": swap_match.group(1).capitalize(),
                    "reason": event_data.get("title", "")
                })
    except Exception as e:
        print(f"Error fetching calendar: {e}")
    
    # Write schedule
    schedule_ref = db.collection("users").document(user_id).collection("schedule").document(semester_id)
    schedule_ref.set({
        "weeklyTemplate": weekly_template,
        "holidays": holidays,
        "daySwaps": day_swaps,
        "lastUpdated": firestore.SERVER_TIMESTAMP
    })
    
    print(f"Generated schedule for {user_id}/{semester_id}: {len(enrolled_section_ids)} sections")


def _parse_days(day_str: str, day_map: dict) -> list:
    """Parse day string like 'MW', 'T R', 'Sunday' into list of day names."""
    days = []
    
    # Try full day name first
    for abbr, full in day_map.items():
        if full.upper() == day_str:
            return [full]
    
    # Split by space if multiple
    tokens = day_str.split()
    if len(tokens) > 1:
        for token in tokens:
            token = token.strip().upper()
            if token in day_map:
                days.append(day_map[token])
    else:
        # Try each character (for "MW", "TR")
        for char in day_str:
            if char in day_map:
                days.append(day_map[char])
    
    return list(set(days))  # Remove duplicates


def _time_to_minutes(time_str: str) -> int:
    """Convert time string to minutes for sorting."""
    try:
        time_str = time_str.strip().upper()
        if "AM" in time_str or "PM" in time_str:
            dt = datetime.strptime(time_str, "%I:%M %p")
        else:
            dt = datetime.strptime(time_str, "%H:%M")
        return dt.hour * 60 + dt.minute
    except:
        return 0

