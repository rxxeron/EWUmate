import firebase_admin
from firebase_admin import firestore, storage
from firebase_functions import https_fn, firestore_fn, storage_fn, options
from datetime import datetime
import re
import base64

# Import optimized modules
from schedule_generator import generate_schedules, is_section_valid
from utils import parse_time_to_minutes
from progress import update_semester_summary, recalculate_academic_stats
from billing_alerts import stop_billing_emergency # Deploys the alert listener
from assign_advising import assign_slot_to_user, parse_schedule_datetime, find_best_slot_for_user
import os

firebase_admin.initialize_app()

def _get_admin_secret():
    """Fetch admin secret from Firestore config/admin document."""
    db = firestore.client()
    doc = db.collection('config').document('admin').get()
    if doc.exists:
        return doc.to_dict().get('secret_key', '')
    return ''

@https_fn.on_call(memory=options.MemoryOption.MB_512, timeout_sec=120)
def upload_file_via_admin(req: https_fn.CallableRequest):
    """Uploads a file (base64) to Firebase Storage via Admin panel."""
    secret = req.data.get('secret')
    expected_secret = _get_admin_secret()
    
    if not expected_secret or secret != expected_secret:
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            "Invalid Admin Secret Key"
        )

    folder = req.data.get('folder')
    filename = req.data.get('filename')
    file_base64 = req.data.get('file_base64')

    if not all([folder, filename, file_base64]):
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            "Missing folder, filename, or file content."
        )

    try:
        bucket = storage.bucket()
        blob_path = f"{folder}/{filename}"
        blob = bucket.blob(blob_path)
        
        # Decode base64
        file_content = base64.b64decode(file_base64)
        
        # Determine content type
        content_type = 'application/pdf'
        if filename.endswith('.json'):
            content_type = 'application/json'
        elif filename.endswith('.txt'):
            content_type = 'text/plain'
            
        blob.upload_from_string(file_content, content_type=content_type)
        
        print(f"Uploaded {blob_path} via admin panel.")
        return {"success": True, "path": blob_path}

    except Exception as e:
        print(f"Upload failed: {e}")
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.INTERNAL,
            f"Upload failed: {str(e)}"
        )

@https_fn.on_call()
def verify_admin_key(req: https_fn.CallableRequest):
    """Verifies the admin secret key without sending any notifications."""
    secret = req.data.get('secret')
    expected_secret = _get_admin_secret()
    
    if not expected_secret or secret != expected_secret:
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            "Invalid Admin Secret Key"
        )
    return {"success": True, "message": "Key verified."}

@https_fn.on_call()
def send_broadcast_notification(req: https_fn.CallableRequest):
    """Sends a broadcast notification to all users."""
    from firebase_admin import messaging
    
    secret = req.data.get('secret')
    expected_secret = _get_admin_secret()
    
    if not expected_secret or secret != expected_secret:
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            "Invalid Admin Secret Key"
        )
    
    title = req.data.get('title')
    body = req.data.get('body')
    link = req.data.get('link')

    if not title or not body:
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            "Title and Body are required"
        )

    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data={
                "click_action": "FLUTTER_NOTIFICATION_CLICK",
                "link": link if link else ""
            },
            topic='all_users'
        )
        
        response = messaging.send(message)
        return {"success": True, "messageId": response}
    except Exception as e:
        print(f"Error sending broadcast: {e}")
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.INTERNAL,
            str(e)
        )

@https_fn.on_call()
def get_app_config(req: https_fn.CallableRequest):
    """Returns general app configuration including currentSemester."""
    db = firestore.client()
    doc = db.collection('config').document('app_info').get()
    if doc.exists:
        return doc.to_dict()
    return {"currentSemester": "Spring 2026"} # Fallback

@https_fn.on_call(timeout_sec=540, memory=options.MemoryOption.MB_512)
def system_master_sync(req: https_fn.CallableRequest):
    """MIGRATION: Syncs all users weekly schedules based on enrollment."""
    secret = req.data.get('secret')
    expected_secret = _get_admin_secret()
    if not expected_secret or secret != expected_secret:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Invalid secret")

    db = firestore.client()
    config = db.collection('config').document('app_info').get().to_dict()
    current_semester = config.get('currentSemester', '').replace(' ', '')
    
    if not current_semester:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.FAILED_PRECONDITION, "Current semester not set in config.")

    users = db.collection('users').get()
    count = 0
    for user_doc in users:
        data = user_doc.to_dict()
        enrolled = data.get('enrolledSections', [])
        if enrolled:
            try:
                _update_user_weekly_schedule(db, user_doc.id, current_semester, enrolled)
                # Recalculate Degree Progress Stats
                recalculate_academic_stats(db, user_doc.id)
                count += 1
            except Exception as e:
                print(f"Failed to sync user {user_doc.id}: {e}")
                
    return {"success": True, "usersSynced": count}

@https_fn.on_call()
def recalculate_all_stats(req: https_fn.CallableRequest):
    """Triggered by Admin Panel to force recalculate CGPA for all users."""
    secret = req.data.get('secret')
    expected_secret = _get_admin_secret()
    if not expected_secret or secret != expected_secret:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Invalid secret")

    db = firestore.client()
    users = db.collection('users').get()
    count = 0
    for user_doc in users:
        try:
            recalculate_academic_stats(db, user_doc.id)
            count += 1
        except Exception as e:
            print(f"Failed stats for {user_doc.id}: {e}")
    
    return {"success": True, "processed": count}

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

    # --- WATCHER / GUARD ADDITION ---
    from usage_guard import check_system_status_and_limit, check_rate_limit
    from sharded_counter import increment_global_counter 

    # 0. Count this invocation (Sampled)
    increment_global_counter()
    
    # 1. Global Kill Switch + Daily Limit Check
    allowed, reason = check_system_status_and_limit("generate_schedules")
    if not allowed:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAVAILABLE, reason)
    
    # 2. User Rate Limit
    if user_id:
        # Limit: 20 generations per hour per user
        allowed, reason = check_rate_limit(user_id, "generate_schedules", limit=20)
        if not allowed:
            raise https_fn.HttpsError(https_fn.FunctionsErrorCode.RESOURCE_EXHAUSTED, reason)
    # --------------------------------

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
    # --- WATCHER GUARD ---
    # For background triggers, we only check global status. 
    # Rate limiting is harder (and maybe unnecessary if logic is cheap).
    from usage_guard import check_system_status_and_limit
    allowed, _ = check_system_status_and_limit("on_enrollment_change")
    if not allowed:
        print("System disabled. Skipping enrollment change trigger.")
        return
    # ---------------------

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
        # Clear simplified schedule on user doc
        db.collection("users").document(user_id).update({
            "weeklySchedule": _empty_week()
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
            content = evt.get('event', '').lower()
            date_str = evt.get('date', '')
            
            # Check for Holidays
            if "holiday" in content:
                holidays.append({"date": date_str, "name": evt.get('event', 'Holiday')})
            
            # Check for Day Swaps (e.g. "Sunday classes will be held on Monday")
            # Logic: Look for "Sunday|Monday... classes" or "acts as Sunday"
            swap_match = re.search(r"(sunday|monday|tuesday|wednesday|thursday|friday|saturday)\s+classes?", content)
            if swap_match:
                day_swaps.append({
                    "date": date_str, 
                    "actsAs": swap_match.group(1).capitalize(), 
                    "reason": evt.get('event', "")
                })
    except Exception as e:
        print(f"Error syncing calendar to schedule: {e}")

    db.collection("users").document(user_id).collection("schedule").document(semester_id).set({
        "weeklyTemplate": weekly_template,
        "holidays": holidays,
        "daySwaps": day_swaps,
        "lastUpdated": firestore.SERVER_TIMESTAMP
    })

    # PROVISION for Node Notification Service
    # Node expects 'weeklySchedule' map on the User document with specific fields 'time' (start-end).
    simplified_schedule = _empty_week()
    for d, classes in weekly_template.items():
        for c in classes:
            # c has startTime, endTime. Node expects "time": "HH:MM AM-HH:MM PM" string?
            # Let's check node expectation: "time": `${session.startTime}-${session.endTime}`
            simplified_schedule[d].append({
                "title": c['courseName'],
                "courseCode": c['courseCode'],
                "time": f"{c['startTime']}-{c['endTime']}",
                "room": c['room']
            })
            
    db.collection("users").document(user_id).update({
        "weeklySchedule": simplified_schedule
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
    # --- WATCHER GUARD ---
    from usage_guard import check_system_status_and_limit
    allowed, _ = check_system_status_and_limit("on_course_marks_change")
    if not allowed:
        print("System disabled. Skipping course marks trigger.")
        return
    # ---------------------

    user_id = event.params["userId"]
    semester_id = event.params["semesterId"]
    
    db = firestore.client()
    print(f"Recalculating semester progress for user {user_id}, semester {semester_id}.")
    
    try:
        update_semester_summary(db, user_id, semester_id)


    except Exception as e:
        print(f"Error updating semester summary: {e}")

@https_fn.on_call()
def assign_advising_slot(req: https_fn.CallableRequest):
    """
    Trigger advising slot assignment for the calling user.
    """
    if not req.auth:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNAUTHENTICATED, message="Must be logged in.")
        
    db = firestore.client()
    result = assign_slot_to_user(db, req.auth.uid)
    return result



@storage_fn.on_object_finalized(region="us-central1", memory=options.MemoryOption.MB_512, timeout_sec=120)
def process_uploaded_document(event: storage_fn.CloudEvent[storage_fn.StorageObjectData]):
    """
    Unified Trigger for Document Processing.
    Paths:
      - /facultylist/       -> Course Schedule
      - /academiccalendar/  -> Academic Calendar
      - /examschedule/      -> Exam Schedule
      - /advisingschedule/  -> Advising Schedule
    """
    file_path = event.data.name
    bucket_name = event.data.bucket
    
    # Identify Folder
    folder = os.path.dirname(file_path)
    filename = os.path.basename(file_path)
    
    # Normalize folder (remove admin_uploads prefix if present, though user said root paths?)
    # User said: "i will always upload the course list in /facultylist"
    # So we check if "facultylist" is IN the path.
    
    print(f"Processing upload: {file_path}")

    # Extract Semester from Filename
    # Patterns: "Spring 2026", "Spring2026", "Summer 2026", "Fall 2026"
    # Case insensitive
    match = re.search(r"(Spring|Summer|Fall)\s*(\d{4})", filename, re.IGNORECASE)
    if match:
        semester_str = f"{match.group(1).capitalize()}{match.group(2)}" # e.g. "Spring2026"
        pretty_semester = f"{match.group(1).capitalize()} {match.group(2)}"
    else:
        print(f"Could not warn extract semester from {filename}. Using timestamp or 'Unknown'.")
        semester_str = "UnknownSemester"
        pretty_semester = "Unknown Semester"

    # Download File
    import google.cloud.storage
    storage_client = google.cloud.storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(file_path)
    
    local_path = f"/tmp/{filename}"
    blob.download_to_filename(local_path)
    
    db = firestore.client()
    
    try:
        # --- ROUTING LOGIC ---
        
        if "facultylist" in file_path.lower():
            # 1. Course Schedule
            print(f"Type: Course Schedule for {semester_str}")
            from parser_course import parse_course_pdf
            
            # We assume we have existing course_titles from previous semesters? Or just parse raw.
            # Passing None for titles means we just use raw data.
            courses = parse_course_pdf(local_path, semester_str, course_titles=None)
            
            if courses:
                batch = db.batch()
                coll_ref = db.collection(f"courses_{semester_str}")
                count = 0
                for c in courses:
                    doc_ref = coll_ref.document(c["docId"])
                    batch.set(doc_ref, c)
                    count += 1
                    if count % 400 == 0:
                        batch.commit()
                        batch = db.batch()
                batch.commit()
                print(f"Uploaded {count} courses.")

        elif "academiccalendar" in file_path.lower():
            # 2. Academic Calendar
            print(f"Type: Academic Calendar for {semester_str}")
            from parser_calendar import parse_academic_calendar
            
            # parse_academic_calendar returns a dict {events: [], holiday_dates: []}
            # Need to verify signature of parser_calendar.py
            events_data = parse_academic_calendar(local_path)
            
            if events_data:
                batch = db.batch()
                coll_ref = db.collection(f"calendar_{semester_str}")
                
                # Clean old?
                # For now just overwrite
                count = 0
                for evt in events_data:
                     # event structure: {date, event, type...}
                     # Create a simple ID
                     # Sanitize date/event for ID
                     evt_id = re.sub(r'\W+', '', evt.get('date', '') + evt.get('event', '')[:10])
                     if not evt_id: evt_id = f"evt_{count}"
                     
                     batch.set(coll_ref.document(evt_id), evt)
                     count += 1
                     if count % 400 == 0:
                         batch.commit()
                         batch = db.batch()
                batch.commit()
                print(f"Uploaded {count} calendar events.")
                
                # --- AUTO SEMESTER SWITCHING LOGIC ---
                # Scan for "University Reopens for {NextSemester}"
                # Event example: "University Reopens for Summer 2026" on "May 12"
                next_sem_found = None
                switch_date = None
                
                for evt in events_data:
                    content = evt.get('event', '')
                    # Regex for "University Reopens for <Semester> <Year>"
                    match_reopen = re.search(r"University Reopens for\s+(Spring|Summer|Fall)\s+(\d{4})", content, re.IGNORECASE)
                    if match_reopen:
                        n_sem = match_reopen.group(1).capitalize() + " " + match_reopen.group(2) # "Summer 2026"
                        date_text = evt.get('date', '') # "May 12"
                        
                        # Parse date (Need Current Year context from filename or just guess)
                        # The calendar file is usually for current year. 
                        # If filename has "2026", use it.
                        year = "2026" # Fallback
                        m_year = re.search(r"(\d{4})", filename)
                        if m_year: year = m_year.group(1)
                        
                        try:
                            # Parse "May 12 2026"
                            dt = datetime.strptime(f"{date_text} {year}", "%B %d %Y")
                            next_sem_found = n_sem
                            switch_date = dt
                            break
                        except Exception as ex:
                            print(f"Error parsing switch date: {date_text} {year} - {ex}")
                
                if next_sem_found and switch_date:
                    print(f"Scheduled Semester Switch: {next_sem_found} on {switch_date.date()}")
                    db.collection('config').document('semester_switching').set({
                        "nextSemester": next_sem_found,
                        "switchDate": switch_date, # Firestore timestamp
                        "status": "pending",
                        "identifiedAt": firestore.SERVER_TIMESTAMP
                    })
                
                # Update app info (Source of Truth for Current Semester)
                db.collection('config').document('app_info').set({
                    "currentSemester": pretty_semester
                }, merge=True)

        elif "examschedule" in file_path.lower():
            # 3. Exam Schedule
            print(f"Type: Exam Schedule for {semester_str}")
            from parser_exam import parse_exam_pdf
            
            exams = parse_exam_pdf(local_path, semester_str)
            
            if exams:
                # Save to single doc or collection?
                # Usually users query by their enrolled courses.
                # A collection "exams_{semester}" where docId = courseCode is best.
                batch = db.batch()
                coll_ref = db.collection(f"exams_{semester_str}")
                
                count = 0
                for ex in exams:
                    # ex structure: {courseCode, examDate, examTime, docId...}
                    if not ex.get('courseCode'): continue
                    
                    doc_ref = coll_ref.document(ex['courseCode'])
                    batch.set(doc_ref, ex)
                    count += 1
                    if count % 400 == 0:
                         batch.commit()
                         batch = db.batch()
                batch.commit()
                print(f"Uploaded {count} exams.")

        elif "advisingschedule" in file_path.lower():
            # 4. Advising Schedule
            print(f"Type: Advising Schedule for {semester_str}")
            
            # Logic: If .eml -> uses eml parser. If .pdf -> ... we need text extraction.
            # Earlier pdf was image-based. Assuming .eml for now or if text.
            if filename.lower().endswith('.eml'):
                from advising_parser import parse_advising_email_content, process_slots
                with open(local_path, 'rb') as f:
                    content = f.read()
                raw_slots = parse_advising_email_content(content)
                processed = process_slots(raw_slots)
                
                if processed:
                    batch = db.batch()
                    coll_ref = db.collection('advising_schedules').document(semester_str).collection('slots')
                    c = 0
                    for slot in processed:
                        batch.set(coll_ref.document(slot['slotId']), slot)
                        c += 1
                    batch.commit()
                    print(f"Uploaded {c} advising slots.")
            else:
                print("PDF Advising Parser not active (image-based PDF detected previously). Please upload .eml version.")

        else:
            print(f"Unknown folder path: {file_path}. Skipping.")


    
    except Exception as e:
        print(f"Error processing file {filename}: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        if os.path.exists(local_path):
            os.remove(local_path)

from firebase_functions import scheduler_fn

@scheduler_fn.on_schedule(schedule="every day 00:00", timezone="Asia/Dhaka", region="us-central1")
def check_semester_switch(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Daily Cron Job: Check if we need to switch the current semester.
    """
    db = firestore.client()
    doc_ref = db.collection('config').document('semester_switching')
    doc = doc_ref.get()
    
    if not doc.exists:
        return
        
    data = doc.to_dict()
    if data.get('status') != 'pending':
        return
        
    switch_date = data.get('switchDate') # Datetime with timezone
    next_semester = data.get('nextSemester')
    
    if not switch_date or not next_semester:
        return

    # Compare dates (Ignoring time)
    # Ensure switch_date is timezone aware if using firestore timestamp
    # Firestore timestamps come back as timezone-aware datetime
    now = datetime.now(switch_date.tzinfo) # Use same timezone
    
    if now >= switch_date:
        print(f"Triggering Semester Switch to {next_semester}")
        
        # 1. Update App Info
        db.collection('config').document('app_info').set({
            "currentSemester": next_semester
        }, merge=True)
        
        # 2. Mark as completed
        doc_ref.update({
            "status": "completed",
            "switchedAt": firestore.SERVER_TIMESTAMP
        })
