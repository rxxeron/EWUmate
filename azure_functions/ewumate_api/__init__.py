"""
EWUmate Azure Functions — Supabase Backend
==========================================
Main endpoints:
  POST /api/generate_schedules    - Schedule generation (backtracking)
  POST /api/parse_calendar        - Manual PDF calendar parser
"""

import json
import logging
import os
import io
import re
import azure.functions as func
from supabase import create_client, Client
import io
from datetime import datetime as _dt
try:
    from pypdf import PdfReader
except ImportError:
    PdfReader = None

from . import calendar_parser
from . import course_parser
from . import exam_parser
from . import advising_parser

# ─── Supabase Config ───────────────────────────────────────────────
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://jwygjihrbwxhehijldiz.supabase.co")
SUPABASE_SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")

def _get_supabase() -> Client:
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


# ═══════════════════════════════════════════════════════════════════
#  GRADE TABLES
# ═══════════════════════════════════════════════════════════════════
GRADE_POINTS = {
    "A+": 4.00, "A": 3.75, "A-": 3.50,
    "B+": 3.25, "B": 3.00, "B-": 2.75,
    "C+": 2.50, "C": 2.25, "D": 2.00, "F": 0.00,
}


# ═══════════════════════════════════════════════════════════════════
#  ENTRY POINT
# ═══════════════════════════════════════════════════════════════════
def main(req: func.HttpRequest) -> func.HttpResponse:
    action = req.route_params.get("action", "")
    logging.info(f"EWUmate API called: action={action}")

    try:
        body = req.get_json()
    except Exception:
        body = {}

    handlers = {
        "generate_schedules": handle_generate_schedules,
        "parse_calendar": handle_parse_calendar,
        "parse_faculty": handle_parse_faculty,
        "parse_exam": handle_parse_exam,
        "parse_advising": handle_parse_advising,
        "parse_faculty_webhook": handle_parse_webhook,
    }

    handler = handlers.get(action)
    if not handler:
        return func.HttpResponse(
            json.dumps({"error": f"Unknown action: {action}"}),
            status_code=404, mimetype="application/json"
        )

    try:
        result = handler(body)
        return func.HttpResponse(
            json.dumps(result, default=str),
            status_code=200, mimetype="application/json"
        )
    except Exception as e:
        logging.exception(f"Error in {action}")
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            status_code=500, mimetype="application/json"
        )


# ═══════════════════════════════════════════════════════════════════
#  SCHEDULE GENERATION  (Backtracking)
# ═══════════════════════════════════════════════════════════════════
from datetime import datetime as _dt

def _parse_time_to_minutes(time_str):
    if not time_str:
        return None
    try:
        t = time_str.strip().upper()
        if "AM" in t or "PM" in t:
            dt = _dt.strptime(t, "%I:%M %p")
        else:
            dt = _dt.strptime(t, "%H:%M")
        return dt.hour * 60 + dt.minute
    except ValueError:
        return None


def _times_conflict(s1, e1, s2, e2):
    if None in (s1, e1, s2, e2):
        return False
    return max(s1, s2) < min(e1, e2)


def _is_day_conflict(d1, d2):
    s1 = set(d1.replace(" ", "").upper())
    s2 = set(d2.replace(" ", "").upper())
    return not s1.isdisjoint(s2)


def _sections_conflict(sec1, sec2):
    for s1 in sec1.get("sessions", []):
        for s2 in sec2.get("sessions", []):
            if not _is_day_conflict(s1.get("day", ""), s2.get("day", "")):
                continue
            if _times_conflict(
                _parse_time_to_minutes(s1.get("startTime") or s1.get("start_time")),
                _parse_time_to_minutes(s1.get("endTime") or s1.get("end_time")),
                _parse_time_to_minutes(s2.get("startTime") or s2.get("start_time")),
                _parse_time_to_minutes(s2.get("endTime") or s2.get("end_time")),
            ):
                return True
    return False


def _is_section_valid(section, filters):
    """Check capacity and user filters."""
    cap = str(section.get("capacity", "0/0"))
    try:
        if "/" not in cap:
            return False
        enr, tot = map(int, cap.split("/"))
        if tot <= 0 or enr >= tot:
            return False
    except Exception:
        return False

    if not filters:
        return True

    excluded_days = filters.get("exclude_days", [])
    if excluded_days:
        day_chars = {
            "sunday": "S", "monday": "M", "tuesday": "T",
            "wednesday": "W", "thursday": "R", "friday": "F", "saturday": "A",
        }
        for sess in section.get("sessions", []):
            day_str = sess.get("day", "").upper()
            for ex in excluded_days:
                c = day_chars.get(ex.lower())
                if c and c in day_str:
                    return False
    return True


def _generate_schedules(sections_map, filters, on_new_schedule=None, limit=80):
    """Backtracking schedule generator with incremental callback."""
    valid = {}
    for code, secs in sections_map.items():
        v = [s for s in secs if _is_section_valid(s, filters)]
        if not v:
            return []  # unsatisfiable
        valid[code] = v

    sorted_codes = sorted(valid.keys(), key=lambda k: len(valid[k]))
    results = []

    def bt(idx, current):
        if idx == len(sorted_codes):
            results.append(list(current))
            if on_new_schedule:
                on_new_schedule(list(current))
            return
        if len(results) >= limit:
            return
        for sec in valid[sorted_codes[idx]]:
            if not any(_sections_conflict(sec, s) for s in current):
                current.append(sec)
                bt(idx + 1, current)
                current.pop()
                if len(results) >= limit:
                    return

    bt(0, [])
    return results


def _fetch_sections_fuzzy(sb, table_name, semester, code):
    """
    Fetches sections for a code, supporting fuzzy 3-to-4 digit matching.
    e.g., 'ENG101' matches 'ENG101', 'ENG7101', etc.
    """
    clean = code.upper().replace(" ", "")
    
    # Identify prefix (letters) and digits
    match = re.search(r"^([A-Z]+)(\d+)$", clean)
    if not match:
        # Fallback to direct match if it doesn't fit standard pattern
        return sb.table(table_name).select("*").eq("semester", semester).eq("code", clean).execute().data or []

    letters = match.group(1)
    digits = match.group(2)
    
    # Build possible codes to search for
    possible_codes = [clean]
    if len(digits) == 3:
        # If 3 digits, also look for 4 digits with common prefixes like '7', '9'
        for prefix in ['7', '9']:
            possible_codes.append(f"{letters}{prefix}{digits}")
    elif len(digits) == 4:
        # If 4 digits, also look for 3 digits by dropping the first digit
        possible_codes.append(f"{letters}{digits[1:]}")

    # Query using 'in' filter
    try:
        result = sb.table(table_name).select("*").eq("semester", semester).in_("code", possible_codes).execute()
        return result.data or []
    except Exception as e:
        logging.warning(f"Failed to query {table_name}: {e}")
        return []


def handle_generate_schedules(body: dict) -> dict:
    """
    Input:  {
        "user_id": "uuid",
        "semester": "Spring2026",
        "courses": ["CSE101", "CSE311", ...],
        "filters": { "exclude_days": ["Friday"] }   // optional
    }
    
    Fetches sections from dynamic course tables, runs backtracking,
    saves results to `schedule_generations`, returns generation ID.
    Supports fuzzy course matching (3-digit metadata -> 4-digit faculty data).
    """
    user_id = body.get("user_id")
    semester = body.get("semester", "").replace(" ", "")
    course_codes = body.get("courses", [])
    filters = body.get("filters", {})

    if not user_id or not semester or not course_codes:
        raise ValueError("user_id, semester, and courses are required")

    # Enforce 3-5 course limit
    if len(course_codes) < 3 or len(course_codes) > 5:
        raise ValueError(f"Schedule generation requires 3-5 courses. Received: {len(course_codes)}")

    sb = _get_supabase()

    # 1) Fetch sections for each course (Fuzzy)
    sections_map = {}
    actual_table = f"courses_{semester.lower()}"
    
    for code in course_codes:
        clean = code.upper().replace(" ", "")
        
        # Try dynamic table first
        secs = _fetch_sections_fuzzy(sb, actual_table, semester, clean)
        
        # Fallback to standard courses table if dynamic table is empty/missing
        if not secs:
            secs = _fetch_sections_fuzzy(sb, "courses", semester, clean)
            
        if not secs:
            raise ValueError(f"No available sections found for {clean} in {semester}")
        
        # Normalize field names (Force camelCase for backtracking logic consistency)
        for s in secs:
            # Normalize sessions keys
            if "sessions" in s and isinstance(s["sessions"], list):
                for sess in s["sessions"]:
                    if "start_time" in sess:
                        sess["startTime"] = sess.pop("start_time")
                    if "end_time" in sess:
                        sess["endTime"] = sess.pop("end_time")
                    if "room_no" in sess:
                        sess["roomNo"] = sess.pop("room_no")
        
        sections_map[clean] = secs

    # 2) Save initial "processing" state to schedule_generations
    import uuid
    gen_id = str(uuid.uuid4())
    
    # Pre-create the record so the app can start streaming
    sb.table("schedule_generations").upsert({
        "id": gen_id,
        "user_id": user_id,
        "semester": semester,
        "courses": course_codes,
        "filters": filters,
        "combinations": [],
        "status": "processing",
        "count": 0,
    }).execute()

    all_combinations = []
    batch_size = 5 # Update DB every N results

    def stream_callback(new_sched):
        nonlocal all_combinations
        combo = {
            "scheduleId": len(all_combinations),
            "sections": {str(j): sec for j, sec in enumerate(new_sched)},
        }
        all_combinations.append(combo)
        
        # Incremental update to database
        if len(all_combinations) % batch_size == 0 or len(all_combinations) == 1:
            try:
                sb.table("schedule_generations").update({
                    "combinations": all_combinations,
                    "count": len(all_combinations),
                }).eq("id", gen_id).execute()
                logging.info(f"Streamed {len(all_combinations)} results for {gen_id}")
            except Exception as e:
                logging.warning(f"Failed to stream update: {e}")

    # 3) Generate (with streaming callback)
    schedules = _generate_schedules(sections_map, filters, on_new_schedule=stream_callback, limit=80)

    if not schedules:
        sb.table("schedule_generations").update({"status": "failed"}).eq("id", gen_id).execute()
        raise ValueError("No valid schedule combinations found. Try adjusting filters or removing courses with no seats.")

    # 4) Final Update (Set status to completed)
    sb.table("schedule_generations").update({
        "combinations": all_combinations,
        "status": "completed",
        "count": len(all_combinations),
    }).eq("id", gen_id).execute()

    return {
        "status": "ok",
        "generationId": gen_id,
        "count": len(all_combinations),
    }


# ═══════════════════════════════════════════════════════════════════
#  4. STORAGE WEBHOOK & SHARED PARSING LOGIC
# ═══════════════════════════════════════════════════════════════════

def handle_parse_webhook(body: dict) -> dict:
    """
    Handles Supabase storage webhook (storage.objects INSERT/UPDATE event).
    Routing is handled in ewumate_webhook function, so this is just a stub
    if called directly (though usually not).
    """
    return {"status": "skipped", "message": "Manual webhook trigger not supported. Use specific parse endpoints."}

def _get_semester_from_path(file_path: str) -> tuple:
    from urllib.parse import unquote
    filename = unquote(os.path.basename(file_path))
    match = re.search(r"(Spring|Summer|Fall)\s*(\d{4})", filename, re.IGNORECASE)
    if not match:
        return None, None, None, False
    
    sem = match.group(1).capitalize()
    year = match.group(2)
    is_dept = any(kw in filename.upper() for kw in ["PHRM", "LAW", "LLB"])
    sem_code = f"{sem}{year}"
    table_sem_code = f"{sem_code}_phrm_llb" if is_dept else sem_code
        
    return sem_code, table_sem_code, f"{sem} {year}", filename, is_dept

def handle_parse_faculty(body: dict) -> dict:
    """Manual trigger: { "file_path": "facultylist/Spring 2026.pdf" }"""
    file_path = body.get("file_path")
    if not file_path: raise ValueError("file_path is required")
    return _do_parse_faculty(file_path)

def handle_parse_calendar(body: dict) -> dict:
    """Manual trigger: { "file_path": "calendar/Spring 2026.pdf" }"""
    file_path = body.get("file_path")
    if not file_path: raise ValueError("file_path is required")
    return _do_parse_calendar(file_path)

def handle_parse_exam(body: dict) -> dict:
    """Manual trigger: { "file_path": "examschedule/Spring 2026.pdf" }"""
    file_path = body.get("file_path")
    if not file_path: raise ValueError("file_path is required")
    return _do_parse_exam(file_path)

def handle_parse_advising(body: dict) -> dict:
    """Manual trigger: { "file_path": "advisingschedule/Spring 2026.eml" }"""
    file_path = body.get("file_path")
    if not file_path: raise ValueError("file_path is required")
    return _do_parse_advising(file_path)

# ─── Logic: Faculty List (Course Schedule) ───────────────────────────

def _do_parse_faculty(file_path: str) -> dict:
    sem_code, table_sem_code, pretty_sem, filename, is_dept = _get_semester_from_path(file_path)
    if not sem_code: return {"error": f"Semester not found in filename: {file_path}"}
    
    table_name = f"courses_{table_sem_code.lower()}"
    sb = _get_supabase()

    try:
        res = sb.storage.from_("academic_documents").download(file_path)
        pdf_bytes = io.BytesIO(res)
        
        meta_res = sb.table("course_metadata").select("code, name, credits, credit_val").execute()
        course_titles = { (r.get("code") or "").upper().replace(" ", ""): r for r in (meta_res.data or []) }
        
        courses = course_parser.parse_course_pdf(pdf_bytes, sem_code, course_titles=course_titles)
        if not courses: return {"status": "warning", "message": "No courses found."}
        
        # Create table if it doesn't exist (idempotent RPC)
        sb.rpc("create_course_table", {"p_semester_code": table_sem_code.lower()}).execute()
        # Clear ALL existing data (table is per-semester, no filter needed)
        sb.table(table_name).delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
        
        for i in range(0, len(courses), 100):
            sb.table(table_name).insert(courses[i:i+100]).execute()
            
        return {"status": "ok", "semester": pretty_sem, "table": table_name, "count": len(courses)}
    except Exception as e:
        logging.exception("parse_faculty failed")
        return {"error": str(e)}

# ─── Logic: Academic Calendar ────────────────────────────────────────

def _do_parse_calendar(file_path: str) -> dict:
    sem_code, table_sem_code, pretty_sem, filename, is_dept = _get_semester_from_path(file_path)
    # Note: Calendar usually contains semester IN content, but we use filename as backup
    
    sb = _get_supabase()
    try:
        res = sb.storage.from_("academic_documents").download(file_path)
        pdf_bytes = io.BytesIO(res)
        
        parsed = calendar_parser.parse_calendar_pdf(pdf_bytes, filename=filename)
        events = parsed.get("events", [])
        metadata = parsed.get("metadata", {})
        
        detected_sem = metadata.get("currentSemester")
        if detected_sem:
            # Normalize detected semester if possible
            match = re.search(r"(Spring|Summer|Fall)\s*(\d{4})", detected_sem, re.IGNORECASE)
            if match:
                sem_code = f"{match.group(1).capitalize()}{match.group(2)}"
                table_sem_code = f"{sem_code}_phrm_llb" if is_dept else sem_code
                pretty_sem = f"{match.group(1).capitalize()} {match.group(2)}"
        
        if not sem_code: return {"error": "Semester not detected from filename or content."}
        table_name = f"calendar_{table_sem_code.lower()}"
        
        sb.rpc("create_calendar_table", {"p_semester_code": table_sem_code.lower()}).execute()
        # Clear ALL rows in the table (table is per-semester, so no filter needed)
        # Previous bug: delete().eq("semester", "Spring2026") missed rows stored as "Spring 2026"
        sb.table(table_name).delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
        
        # Normalize semester field in events to use pretty format consistently
        for evt in events:
            evt["semester"] = pretty_sem
        
        if events:
            for i in range(0, len(events), 100):
                sb.table(table_name).insert(events[i:i+100]).execute()
                
        # Handle Config Updates (Shared with Phase 1 logic)
        # For departmental calendars, we update specialized active_semester record (ID 2)
        config_updates = _update_semester_config(sb, detected_sem, metadata, events=events, is_dept=is_dept)
        
        return {"status": "ok", "semester": pretty_sem, "table": table_name, "count": len(events), "config_updates": config_updates}
    except Exception as e:
        logging.exception("_do_parse_calendar failed")
        return {"error": str(e)}

def _update_semester_config(sb, detected_semester, metadata, events=None, is_dept=False):
    """
    Updates the dedicated 'active_semester' table dynamically.
    
    semester_type: 'tri' (Standard) or 'bi' (PHRM/LLB)
    """
    updates = []
    events = events or []
    try:
        # 1. Normalize current semester and get code
        curr_sem = detected_semester
        curr_code = None
        if curr_sem:
            match = re.search(r"(Spring|Summer|Fall)\s*(\d{4})", curr_sem, re.IGNORECASE)
            if match:
                curr_code = f"{match.group(1).capitalize()}{match.group(2)}"
        
        # 2. Fetch existing config by semester_type
        semester_type = 'bi' if is_dept else 'tri'
        existing = sb.table("active_semester").select("*").eq("semester_type", semester_type).maybe_single().execute()
        existing_data = existing.data if existing else None
        existing_curr_code = existing_data.get("current_semester_code") if existing_data else None

        # 3. Extract milestones (Picking earliest/latest dates found)
        advising_start = None
        classes_start = None
        grades_start = None
        grades_deadline = None
        u_reopens = None
        next_sem_start = None
        
        for evt in events:
            evt_name = evt.get("name", "").lower()
            evt_date = evt.get("date")
            if not evt_date or not isinstance(evt_date, str) or len(evt_date) < 10: continue

            if "online advising" in evt_name or "advising of courses" in evt_name:
                if not advising_start or evt_date < advising_start:
                    advising_start = evt_date

            if "first day of classes" in evt_name or "classes begin" in evt_name:
                # If it mentions "next" or a future semester, it's for next sem
                if "summer" in evt_name or "fall" in evt_name or "spring" in evt_name:
                    if not next_sem_start or evt_date < next_sem_start:
                        next_sem_start = evt_date
                else:
                    if not classes_start or evt_date < classes_start:
                        classes_start = evt_date

            if "grade submission" in evt_name:
                if not grades_start or evt_date < grades_start:
                    grades_start = evt_date
                if not grades_deadline or evt_date > grades_deadline:
                    grades_deadline = evt_date

            if "university reopens" in evt_name:
                if not u_reopens or evt_date < u_reopens:
                    u_reopens = evt_date

        # 4. Integrate Metadata from Parser (High Precision)
        meta = metadata or {}
        
        # 5. Decide what to update
        payload = {"semester_type": semester_type, "is_active": True, "updated_at": _dt.now().isoformat()}
        if existing_data and 'id' in existing_data:
            payload['id'] = existing_data['id']
            
        is_early_upload = False
        if curr_code and existing_curr_code and curr_code != existing_curr_code:
            is_early_upload = True
            
        logging.info(f"Semester Sync: Detected={curr_code}, Existing={existing_curr_code}, is_early={is_early_upload}")

        if is_early_upload:
            payload["next_semester"] = curr_sem
            payload["next_semester_code"] = curr_code
            
            # Map precise metadata with fallbacks
            payload["upcoming_semester_start_date"] = meta.get("upcomingSemesterStartDate") or next_sem_start
            payload["switch_date"] = meta.get("switchDate") or u_reopens
            payload["grade_submission_start"] = meta.get("gradeSubmissionStart") or grades_start
            payload["grade_submission_deadline"] = meta.get("gradeSubmissionDeadline") or grades_deadline
            payload["advising_start_date"] = meta.get("advisingStartDate") or advising_start
        else:
            payload["current_semester"] = curr_sem
            payload["current_semester_code"] = curr_code
            
            # Map current milestones
            payload["current_semester_start_date"] = meta.get("currentSemesterStartDate") or classes_start
            payload["advising_start_date"] = meta.get("advisingStartDate") or advising_start
            payload["grade_submission_start"] = meta.get("gradeSubmissionStart") or grades_start
            payload["grade_submission_deadline"] = meta.get("gradeSubmissionDeadline") or grades_deadline
            payload["switch_date"] = meta.get("switchDate") or u_reopens

            # Impending semester metadata if available
            if meta.get("nextSemester"):
                 payload["next_semester"] = meta.get("nextSemester")
                 match = re.search(r"(Spring|Summer|Fall)\s*(\d{4})", meta.get("nextSemester"), re.IGNORECASE)
                 if match: payload["next_semester_code"] = f"{match.group(1).capitalize()}{match.group(2)}"
                 
            if meta.get("upcomingSemesterStartDate") or next_sem_start:
                 payload["upcoming_semester_start_date"] = meta.get("upcomingSemesterStartDate") or next_sem_start
            
        logging.info(f"Upserting active_semester payload: {payload}")
        sb.table("active_semester").upsert(payload).execute()
        
        # Only record success messages AFTER the db operation succeeds
        if is_early_upload:
            updates.append(f"Detected UPCOMING semester: {curr_sem}. Staging Next Semester milestones.")
        else:
            updates.append(f"Updated CURRENT semester: {curr_sem}.")
        
    except Exception as e:
        logging.warning(f"Failed to update active_semester table: {e}")
    return updates

# ─── Logic: Exam Schedule ───────────────────────────────────────────

def _do_parse_exam(file_path: str) -> dict:
    sem_code, table_sem_code, pretty_sem, filename, is_dept = _get_semester_from_path(file_path)
    if not sem_code: return {"error": f"Semester not found in filename: {file_path}"}
    
    table_name = f"exams_{table_sem_code.lower()}"
    sb = _get_supabase()

    try:
        res = sb.storage.from_("academic_documents").download(file_path)
        pdf_bytes = io.BytesIO(res)
        
        exams = exam_parser.parse_exam_pdf(pdf_bytes, sem_code)
        if not exams: return {"status": "warning", "message": "No exam mappings found."}
        
        # Create table if it doesn't exist (idempotent RPC)
        sb.rpc("create_exam_table", {"p_semester_code": table_sem_code.lower()}).execute()
        # Clear ALL existing data (table is per-semester, no filter needed)
        sb.table(table_name).delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
        
        for i in range(0, len(exams), 100):
            sb.table(table_name).insert(exams[i:i+100]).execute()
            
        # [NEW] Trigger the Supabase Edge Function to match and distribute exam dates to all user profiles
        try:
            import urllib.request
            import urllib.parse
            import json
            
            edge_func_url = f"{SUPABASE_URL}/functions/v1/match-exams"
            req_data = json.dumps({"semester": table_sem_code.lower()}).encode("utf-8")
            edge_req = urllib.request.Request(
                edge_func_url,
                data=req_data,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}"
                },
                method="POST"
            )
            
            # Fire and forget (timeout=2) or wait for a small timeout to let it buffer
            try:
                urllib.request.urlopen(edge_req, timeout=5)
            except Exception as e:
                logging.warning(f"Timeout or error invoking match-exams Edge Function: {str(e)}")
                
        except Exception as e:
            logging.error(f"Failed to prepare Edge Function invocation: {str(e)}")
            
        return {"status": "ok", "semester": pretty_sem, "table": table_name, "count": len(exams)}
    except Exception as e:
        logging.exception("_do_parse_exam failed")
        return {"error": str(e)}

# ─── Logic: Advising Schedule ────────────────────────────────────────

def _do_parse_advising(file_path: str) -> dict:
    sem_code, table_sem_code, pretty_sem, filename, is_dept = _get_semester_from_path(file_path)
    if not sem_code: return {"error": f"Semester not found in filename: {file_path}"}
    
    table_name = f"advising_{table_sem_code.lower()}"
    sb = _get_supabase()

    try:
        res = sb.storage.from_("academic_documents").download(file_path)
        
        if filename.lower().endswith(".eml"):
            slots = advising_parser.parse_advising_eml(res, sem_code)
        else:
            return {"error": "Only .eml files are supported for advising schedule for now."}
            
        if not slots: return {"status": "warning", "message": "No advising slots found."}
        
        # Create table if it doesn't exist (idempotent RPC)
        sb.rpc("create_advising_table", {"p_semester_code": table_sem_code.lower()}).execute()
        # Clear ALL existing data (table is per-semester, no filter needed)
        sb.table(table_name).delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
        
        for i in range(0, len(slots), 100):
            sb.table(table_name).insert(slots[i:i+100]).execute()
            
        # [NEW] Trigger the Supabase Edge Function to match and assign advising slots to user profiles
        try:
            import urllib.request
            import urllib.parse
            import json
            
            edge_func_url = f"{SUPABASE_URL}/functions/v1/match-advising"
            req_data = json.dumps({"semester": table_sem_code.lower()}).encode("utf-8")
            edge_req = urllib.request.Request(
                edge_func_url,
                data=req_data,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}"
                },
                method="POST"
            )
            
            try:
                urllib.request.urlopen(edge_req, timeout=10)
                logging.info(f"Successfully triggered match-advising for {table_sem_code}")
            except Exception as e:
                logging.warning(f"Timeout or error invoking match-advising Edge Function: {str(e)}")
                
        except Exception as e:
            logging.error(f"Failed to prepare match-advising invocation: {str(e)}")
            
        return {"status": "ok", "semester": pretty_sem, "table": table_name, "count": len(slots)}
    except Exception as e:
        logging.exception("_do_parse_advising failed")
        return {"error": str(e)}
