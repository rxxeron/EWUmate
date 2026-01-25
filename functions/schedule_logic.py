"""
Cloud Function: Personalized Schedule Generation
Trigger: Firestore Document Write on user's enrolled courses
Output: Schedule document with weekly template, holidays, and day swaps
"""
from firebase_functions import firestore_fn, https_fn, options
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


@https_fn.on_request(region="us-central1", memory=options.MemoryOption.MB_512, timeout_sec=540)
def regenerate_all_schedules(req: https_fn.Request) -> https_fn.Response:
    """
    HTTP Trigger to manually regenerate the schedule for ALL users
    for the currently configured semester.
    """
    db = firestore.client()
    
    # 1. Get current semester
    try:
        config_doc = db.collection('config').document('app_info').get()
        if config_doc.exists:
            semester_id = config_doc.to_dict().get('currentSemester', '')
        else:
            semester_id = ''
    except Exception as e:
        print(f"Error getting config: {e}")
        return https_fn.Response(f"Error getting config: {e}", status=500)

    if not semester_id:
        msg = "No current semester configured in config/app_info."
        print(msg)
        return https_fn.Response(msg, status=400)
    
    semester_id_normalized = semester_id.replace(' ', '')
    print(f"Starting schedule regeneration for all users for semester: {semester_id_normalized}")

    # 2. Get all users
    try:
        users_stream = db.collection("users").stream()
        user_count = 0
        for user_doc in users_stream:
            user_id = user_doc.id
            user_data = user_doc.to_dict()
            enrolled_sections = set(user_data.get("enrolledSections", []))
            
            if not enrolled_sections:
                print(f"Skipping user {user_id}: no enrolled sections.")
                continue

            print(f"Processing user {user_id} with {len(enrolled_sections)} sections...")
            try:
                # 3. Call the internal logic for each user
                _generate_schedule_for_user(db, user_id, semester_id_normalized, enrolled_sections)
                user_count += 1
            except Exception as e:
                print(f"!!! FAILED to generate schedule for user {user_id}: {e}")

        final_msg = f"Successfully regenerated schedules for {user_count} users for semester {semester_id}."
        print(final_msg)
        return https_fn.Response(final_msg)

    except Exception as e:
        print(f"An error occurred during user iteration: {e}")
        return https_fn.Response(f"An error occurred: {e}", status=500)


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
    all_courses_stream = master_courses_ref.stream() # Fetch all courses once

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
    
    # Create a list from the stream to allow multiple iterations if needed
    all_courses_list = list(all_courses_stream)

    for course_doc in all_courses_list:
        # Check if the doc ID is in the user's enrolled sections
        if course_doc.id not in enrolled_section_ids:
            continue

        try:
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
            print(f"Error processing section {course_doc.id}: {e}")

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
    """
    Parse day string like 'MW', 'T R', 'Sunday', 'SAT' into a list of day names.
    Correctly handles multi-letter abbreviations.
    """
    days = set()
    day_str = day_str.upper().strip()

    # Create a sorted list of abbreviations, longest first, to ensure "SUN" is checked before "SU" or "S"
    sorted_abbrs = sorted(day_map.keys(), key=len, reverse=True)

    # First, handle space-separated abbreviations like "T R"
    tokens = day_str.split()

    if len(tokens) > 1:
        # If we have spaces, assume each token is a day
        for token in tokens:
            if token in day_map:
                days.add(day_map[token])
    else:
        # If no spaces, parse the string (e.g., "MWF", "SAT")
        s = day_str
        i = 0
        while i < len(s):
            found_match = False
            # Check for longest possible match starting at index i
            for abbr in sorted_abbrs:
                if s[i:].startswith(abbr):
                    days.add(day_map[abbr])
                    i += len(abbr)
                    found_match = True
                    break # Move to the next position after the matched abbreviation
            if not found_match:
                # If no known abbreviation matches, just advance one character
                i += 1
                
    return list(days)


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
