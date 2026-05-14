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
import uuid
from datetime import datetime as _dt
import azure.functions as func
from supabase import create_client, Client
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.units import inch

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
#  ENTRY POINT
# ═══════════════════════════════════════════════════════════════════
def main(req: func.HttpRequest) -> func.HttpResponse:
    action = req.route_params.get("action", "")
    logging.info(f"EWUmate API called: action={action}")

    try:
        body = req.get_json()
    except Exception:
        body = {}

    # Special handling for binary PDF generation
    if action == "generate_pdf":
        try:
            pdf_bytes = handle_generate_pdf(body)
            return func.HttpResponse(
                pdf_bytes,
                status_code=200,
                mimetype="application/pdf",
                headers={
                    "Content-Disposition": f"attachment; filename=CoverPage.pdf",
                    "Access-Control-Allow-Origin": "*", # Enable CORS for browser
                }
            )
        except Exception as e:
            logging.exception("PDF Generation failed")
            return func.HttpResponse(json.dumps({"error": str(e)}), status_code=500, headers={"Access-Control-Allow-Origin": "*"})

    handlers = {
        "generate_schedules": handle_generate_schedules,
        "parse_calendar": handle_parse_calendar,
        "parse_faculty": handle_parse_faculty,
        "parse_exam": handle_parse_exam,
        "parse_advising": handle_parse_advising,
        "parse_faculty_webhook": handle_parse_webhook,
        "sync_api_courses": handle_sync_api_courses,
        "generate_pdf": handle_generate_pdf,
    }

    handler = handlers.get(action)
    if not handler:
        return func.HttpResponse(
            json.dumps({"error": f"Unknown action: {action}"}),
            status_code=404, mimetype="application/json",
            headers={"Access-Control-Allow-Origin": "*"}
        )

    try:
        result = handler(body)
        return func.HttpResponse(
            json.dumps(result, default=str),
            status_code=200, mimetype="application/json",
            headers={"Access-Control-Allow-Origin": "*"}
        )
    except Exception as e:
        logging.exception(f"Error in {action}")
        return func.HttpResponse(
            json.dumps({"error": str(e), "action": action}),
            status_code=500, mimetype="application/json",
            headers={"Access-Control-Allow-Origin": "*"}
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
    return max(s1, s2) <= min(e1, e2)


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
    # 1. Basic Capacity Check
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

    # 2. Selected Faculty Filter
    selected_faculties = filters.get("selected_faculties", {})
    if selected_faculties:
        course_code = (section.get("course_code") or section.get("code") or "").upper().replace(" ", "")
        allowed_for_this_course = selected_faculties.get(course_code)
        
        if allowed_for_this_course and isinstance(allowed_for_this_course, list) and len(allowed_for_this_course) > 0:
            faculty_initials = (section.get("faculty_initials") or "TBA").upper().strip()
            if faculty_initials not in [f.upper().strip() for f in allowed_for_this_course]:
                return False

    # 3. Excluded Days
    excluded_days = filters.get("exclude_days", [])
    if excluded_days:
        day_chars = {
            "sunday": "S", "monday": "M", "tuesday": "T",
            "wednesday": "W", "thursday": "R", "friday": "F", "saturday": "A",
        }
        # Database uses 'schedule_data', but solver uses 'sessions' internally
        sessions = section.get('sessions', [])
        if not isinstance(sessions, list):
            return []
        for sess in sessions:
            day_str = sess.get("day", "").upper()
            for ex in excluded_days:
                c = day_chars.get(ex.lower())
                if c and c in day_str:
                    return False
    return True


def _generate_schedules(sections_map, filters, on_new_schedule=None, limit=300):
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
        return sb.table(table_name).select("*").eq("course_code", clean).execute().data or []

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
        possible_codes.append(f"{letters}{str(digits)[1:]}")

    # Query using 'in' filter
    try:
        result = sb.table(table_name).select("*").in_("course_code", possible_codes).execute()
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

    # Enforce 2-10 course limit
    if len(course_codes) < 2 or len(course_codes) > 10:
        raise ValueError(f"Schedule generation requires 2-10 courses. Received: {len(course_codes)}")

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
        
        # Normalize field names
        for s in secs:
            s["id"] = str(s.get("id"))
            s["code"] = s.get("course_code") or s.get("code", "")
            s["section"] = s.get("section_number") or str(s.get("section", ""))
            s["capacity"] = s.get("capacity", "")
            s["credits"] = str(s.get("credit_val", "3.0"))
            s["courseName"] = s.get("course_name", "")
            
            # BRIDGE: Read 'schedule_data' (DB) but map to 'sessions' (Flutter Model)
            s["sessions"] = s.get("schedule_data", [])
            
            # Normalize sessions keys
            if "sessions" in s and isinstance(s["sessions"], list):
                for sess in s["sessions"]:
                    if "start_time" in sess:
                        sess["startTime"] = sess.pop("start_time")
                    elif "startTime" not in sess:
                        sess["startTime"] = ""
                    if "end_time" in sess:
                        sess["endTime"] = sess.pop("end_time")
                    elif "endTime" not in sess:
                        sess["endTime"] = ""
                    if "room_no" in sess:
                        sess["room"] = sess.pop("room_no")
                    elif "room" not in sess:
                        sess["room"] = ""
        sections_map[clean] = secs

    # 2) Initialize or Resume session in schedule_generations
    import uuid
    gen_id = body.get("generation_id") or str(uuid.uuid4())
    
    # Check if record already exists to avoid resetting combinations on restart
    try:
        existing = sb.table("schedule_generations").select("status, combinations").eq("id", gen_id).execute()
        if not existing.data:
            # First time: Create the record
            sb.table("schedule_generations").insert({
                "id": gen_id,
                "user_id": user_id,
                "semester": semester,
                "courses": course_codes,
                "filters": filters,
                "combinations": [],
                "status": "processing",
                "count": 0,
            }).execute()
        else:
            # Resuming: Check status
            if existing.data[0].get("status") == "completed":
                 return {
                    "status": "ok",
                    "generationId": gen_id,
                    "count": len(existing.data[0].get("combinations", [])),
                    "message": "Already completed"
                }
            # Update status to processing if it was failed/paused
            sb.table("schedule_generations").update({"status": "processing"}).eq("id", gen_id).execute()
    except Exception as e:
        logging.warning(f"Session check/init failed: {e}")

    all_combinations = []
    batch_size = 25 
    gen_limit = min(body.get("limit", 1000), 1000) 

    def stream_callback(new_sched):
        nonlocal all_combinations
        if len(all_combinations) >= gen_limit:
            return

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
            except Exception as e:
                logging.warning(f"Streamed batch update failed: {e}")

    # 3) Generate (with optimized backtracking)
    try:
        schedules = _generate_schedules(sections_map, filters, on_new_schedule=stream_callback, limit=gen_limit)
    except Exception as e:
        logging.exception("Backtracking engine crashed")
        sb.table("schedule_generations").update({"status": "failed"}).eq("id", gen_id).execute()
        raise e

    if not all_combinations:
        sb.table("schedule_generations").update({"status": "failed"}).eq("id", gen_id).execute()
        raise ValueError("No valid schedule combinations found. Try adjusting filters or removing courses with no seats.")

    # 4) Final Update (Set status to completed)
    try:
        sb.table("schedule_generations").update({
            "combinations": all_combinations,
            "status": "completed",
            "count": len(all_combinations),
        }).eq("id", gen_id).execute()
    except Exception as e:
        logging.error(f"Final completion update failed: {e}")
        sb.table("schedule_generations").update({"status": "completed"}).eq("id", gen_id).execute()

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
    sem_code = f"{sem}{year}" # "Spring2025"
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

# ─── NEW: Direct API Scraper → DB (No PDF / No Storage needed) ──────

def handle_sync_api_courses(body: dict) -> dict:
    """
    Accepts pre-scraped course data directly from the Admin Panel scraper.

    Request body:
    {
        "semester": "Summer2026",   <- semester code (normalized, no spaces)
        "courses": [                <- array from scraper_server.py output
            {
                "code":        "CSE101",
                "section":     "1",
                "faculty":     "BCR",
                "capacity":    "15/30",
                "course_name": "Data Structures",
                "credits":     3.0,
                "sessions": [{
                    "type":      "Theory",
                    "day":       "MW",
                    "startTime": "08:30 AM",
                    "endTime":   "10:00 AM",
                    "room":      "220",
                    "faculty":   "BCR"
                }]
            },
            ...
        ]
    }
    """
    semester = body.get("semester", "").strip()
    courses   = body.get("courses", [])

    if not semester:
        raise ValueError("'semester' is required (e.g. 'Summer2026')")
    if not courses:
        raise ValueError("'courses' array is empty")

    # Normalize semester code: remove spaces/dashes → lowercase for table name
    import re
    clean_sem  = re.sub(r'[\s\-_]+', '', semester)          # "Summer2026"
    table_name = f"courses_{clean_sem.lower()}"             # "courses_summer2026"

    logging.info(f"[sync_api_courses] semester={semester}, table={table_name}, count={len(courses)}")

    sb = _get_supabase()

    # 1. Normalize course code (strip 7/8 prefix digits, same as _do_parse_faculty)
    def normalize_code(code):
        if not code: return ""
        # Remove spaces and hyphens
        clean = code.upper().replace(" ", "").replace("-", "")
        # If there are 4 digits at the end, remove the first one
        import re
        return re.sub(r'^([A-Z]+)\d(\d{3})$', r'\1\2', clean)

    # 1.5 Fetch master metadata for enrichment
    meta_res = sb.table("course_metadata").select("code, name, credit_val").execute()
    meta_map = { (r.get("code") or "").upper().replace(" ", ""): r for r in (meta_res.data or []) }

    # 2. Map scraper output → live DB schema (mirrors _do_parse_faculty lines 489-498)
    mapped_courses = []
    unique_seen = set()
    for c in courses:
        raw_code = (c.get("code") or "").strip()
        sec      = str(c.get("section") or "").strip()

        if not raw_code or not sec:
            continue

        clean_code = normalize_code(raw_code)
        key = (clean_code, sec)
        if key in unique_seen:
            continue
        unique_seen.add(key)

        # Enrichment from master catalog
        master = meta_map.get(clean_code)
        final_name = (master.get("name") if master else "") or c.get("course_name") or ""
        
        # Safe credit conversion
        try:
            raw_cred = (master.get("credit_val") if master else None) or c.get("credits")
            final_cred = float(raw_cred) if raw_cred not in (None, "", " ") else 3.0
        except:
            final_cred = 3.0

        mapped_courses.append({
            "course_code":      clean_code,
            "original_code":    raw_code,
            "section_number":   sec,
            "faculty_initials":  c.get("faculty") or "TBA",
            "dedicated_department": c.get("dedicated_department") or "",
            "capacity":          c.get("capacity") or "0/0",
            "schedule_data":     c.get("sessions") or [],
            "course_name":       final_name,
            "credit_val":        final_cred,
            "faculty_full_name": re.sub(r'^(Mr|Ms|Mrs)\.?\s+', '', c.get("faculty_full_name") or "", flags=re.IGNORECASE).title(),
            "faculty_designation": c.get("faculty_designation") or "",
        })

    if not mapped_courses:
        return {"status": "warning", "message": "No valid courses after normalization."}

    # 3. Create table if it doesn't exist (idempotent RPC)
    sb.rpc("create_course_table", {"p_semester_code": clean_sem.lower()}).execute()

    import time
    # 4. Smart upsert: fetch existing → update matched, insert new, delete removed
    existing_courses = []
    for retry in range(6):
        try:
            if retry > 0:
                time.sleep(2.0) # Only sleep on retries
            
            all_existing = []
            offset = 0
            while True:
                chunk = sb.table(table_name).select("id, course_code, section_number").range(offset, offset + 999).execute()
                all_existing.extend(chunk.data or [])
                if len(chunk.data or []) < 1000:
                    break
                offset += 1000
            existing_courses = all_existing
            break
        except Exception as e:
            if retry == 5:
                raise e

    existing_map = {}
    for ec in existing_courses:
        cc  = (ec.get("course_code") or "").upper().replace(" ", "")
        sec = (ec.get("section_number") or "").upper().replace(" ", "")
        if cc and sec:
            existing_map[(cc, sec)] = ec.get("id")

    # Tag records that already exist with their DB id
    seen_ids = set()
    for mc in mapped_courses:
        cc  = (mc["course_code"] or "").upper().replace(" ", "")
        sec = (mc["section_number"] or "").upper().replace(" ", "")
        key = (cc, sec)
        if key in existing_map:
            mc["id"] = existing_map[key]
            seen_ids.add(existing_map[key])

    # Delete records that are no longer in the new data
    ids_to_delete = [uid for uid in existing_map.values() if uid not in seen_ids]
    for i in range(0, len(ids_to_delete), 100):
        sb.table(table_name).delete().in_("id", ids_to_delete[i:i+100]).execute()

    new_courses     = [mc for mc in mapped_courses if "id" not in mc]
    updated_courses = [mc for mc in mapped_courses if "id" in mc]

    # Insert new
    for i in range(0, len(new_courses), 100):
        sb.table(table_name).insert(new_courses[i:i+100]).execute()

    # Upsert updated (with UUID)
    for i in range(0, len(updated_courses), 100):
        sb.table(table_name).upsert(updated_courses[i:i+100]).execute()

    # Log the sync event for tracking
    try:
        sb.table("scraper_logs").insert({
            "semester": semester,
            "added": len(new_courses),
            "updated": len(updated_courses),
            "deleted": len(ids_to_delete),
            "status": "success",
            "report": {
                "message": "Sync complete",
                "total": len(mapped_courses)
            }
        }).execute()
    except: pass # Don't fail the sync if logging fails

    return {
        "status":    "ok",
        "message": f"Sync Complete for {semester}",
        "semester":  semester,
        "table":     table_name,
        "total":     len(mapped_courses),
        "inserted":  len(new_courses),
        "updated":   len(updated_courses),
        "deleted":   len(ids_to_delete),
    }


# ─── Logic: Faculty List (Course Schedule) ───────────────────────────

def _do_parse_faculty(file_path: str) -> dict:
    sem_code, table_sem_code, pretty_sem, filename, is_dept = _get_semester_from_path(file_path)
    if not sem_code: return {"error": f"Semester not found in filename: {file_path}"}
    
    table_name = f"courses_{table_sem_code.lower()}"
    sb = _get_supabase()

    try:
        res = sb.storage.from_("academic_documents").download(file_path)
        pdf_bytes = io.BytesIO(res)
        
        meta_res = sb.table("course_metadata").select("code, name, credit_val").execute()
        course_titles = { (r.get("code") or "").upper().replace(" ", ""): r for r in (meta_res.data or []) }
        
        courses = course_parser.parse_course_pdf(pdf_bytes, sem_code, course_titles=course_titles)
        if not courses: return {"status": "warning", "message": "No courses found."}

        # Map to new database schema
        def normalize(code):
            if not code: return ""
            # Remove spaces and hyphens
            clean = code.upper().replace(" ", "").replace("-", "")
            # If there are 4 digits at the end, remove the first one
            import re
            return re.sub(r'^([A-Z]+)\d(\d{3})$', r'\1\2', clean)

        mapped_courses = []
        unique_seen = set()
        for c in courses:
            clean_code = normalize(c.get("code"))
            sec = c.get("section")
            
            key = (clean_code, sec)
            if key in unique_seen:
                continue
            unique_seen.add(key)
            
            mapped_courses.append({
                "course_code": clean_code,
                "original_code": c.get("code"),
                "section_number": sec,
                "faculty_initials": c.get("faculty"),
                "capacity": c.get("capacity"),
                "schedule_data": c.get("sessions"),
                "course_name": c.get("course_name"),
                "credit_val": float(c.get("credits", 0) or 0),
                "faculty_full_name": re.sub(r'^(Mr|Ms|Mrs)\.?\s+', '', c.get("faculty_full_name") or "", flags=re.IGNORECASE).title(),
                "faculty_designation": c.get("faculty_designation") or "",
            })

        # Create table if it doesn't exist (idempotent RPC)
        sb.rpc("create_course_table", {"p_semester_code": table_sem_code.lower()}).execute()
        
        # Let PostgREST schema cache reload completely before querying the new table
        import time
        existing_courses = []
        for retry in range(6):
            try:
                time.sleep(1.5) # Wait for schema cache to refresh
                
                # Supabase has a 1000 row limit by default. We must paginate.
                all_existing = []
                offset = 0
                while True:
                    chunk_res = sb.table(table_name).select("id, course_code, section_number").range(offset, offset + 999).execute()
                    chunk_data = chunk_res.data or []
                    all_existing.extend(chunk_data)
                    if len(chunk_data) < 1000:
                        break
                    offset += 1000
                    
                existing_courses = all_existing
                
                break # Success!
            except Exception as wait_e:
                if retry == 5:
                    logging.warning(f"Schema cache didn't refresh in time: {wait_e}")
                    raise wait_e
        
        existing_map = {}
        for ec in existing_courses:
            cc = ec.get("course_code")
            sec = ec.get("section_number")
            if cc and sec:
                existing_map[(str(cc).upper().replace(" ", ""), str(sec).upper().replace(" ", ""))] = ec.get("id")

        seen_ids = set()
        for mc in mapped_courses:
            cc = mc.get("course_code")
            sec = mc.get("section_number")
            if cc and sec:
                key = (str(cc).upper().replace(" ", ""), str(sec).upper().replace(" ", ""))
                if key in existing_map:
                    rec_id = existing_map[key]
                    mc["id"] = rec_id
                    seen_ids.add(rec_id)
        
        ids_to_delete = [uid for uid in existing_map.values() if uid not in seen_ids]
        if ids_to_delete:
            for i in range(0, len(ids_to_delete), 100):
                batch = ids_to_delete[i:i+100]
                sb.table(table_name).delete().in_("id", batch).execute()      

        new_courses = [mc for mc in mapped_courses if "id" not in mc]
        updated_courses = [mc for mc in mapped_courses if "id" in mc]

        # Insert new courses (without UUIDs)
        for i in range(0, len(new_courses), 100):
            sb.table(table_name).insert(new_courses[i:i+100]).execute()

        # Upsert updated courses (with UUIDs)
        for i in range(0, len(updated_courses), 100):
            sb.table(table_name).upsert(updated_courses[i:i+100]).execute()    

        return {
            "status": "ok",
            "semester": pretty_sem,
            "table": table_name,
            "upserted": len(mapped_courses),
            "deleted": len(ids_to_delete)
        }
    except Exception as e:
        import traceback
        logging.error(f"Parse faculty failed: {e}")
        return {"error": str(e)}

def _do_parse_calendar(file_path: str) -> dict:
    sem_code, table_sem_code, pretty_sem, filename, is_dept = _get_semester_from_path(file_path)
    if not sem_code: return {"error": f"Semester not found in filename: {file_path}"}
    
    table_name = f"calendar_{table_sem_code.lower()}"
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
        
        import time
        sb.rpc("create_calendar_table", {"p_semester_code": table_sem_code.lower()}).execute()
        
        # Wait for Supabase PostgREST cache to sync
        for retry in range(6):
            try:
                time.sleep(1.5)
                # Clear ALL rows in the table
                sb.table(table_name).delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
                break # Success!
            except Exception as wait_e:
                if retry == 5: raise wait_e
        for evt in events:
            evt["semester"] = pretty_sem
        
        if events:
# Map to new calendar schema before inserting
            mapped_events = []
            for item in events:
                track = 'bi_semester' if is_dept else 'tri_semester'
                mapped_events.append({
                    "event_date": item.get("date"),
                    "title": item.get("name") or item.get("title", ""),
                    "type": item.get("type", "General"),
                    "target_track": track
                })

            for i in range(0, len(mapped_events), 100):
                batch = mapped_events[i:i+100]
                try:
                    resp = sb.table(table_name).insert(batch).execute()
                    logging.info(f"Inserted batch of {len(batch)} into {table_name}")
                except Exception as e:
                    logging.error(f"Supabase insertion failed for {table_name}: {str(e)}")
                    # Individual retry for debugging
                    for item in batch:
                        try:
                            sb.table(table_name).insert(item).execute()
                        except Exception as inner_e:
                            logging.error(f"Row insertion failed: {str(inner_e)} | Row: {item}")
                
        # Handle Config Updates (Shared with Phase 1 logic)
        # Use pretty_sem (from filename) as fallback for detected_sem
        sync_sem = detected_sem or pretty_sem
        # config_updates = _update_semester_config(sb, sync_sem, metadata, events=events, is_dept=is_dept)
        config_updates = {}

        return {"status": "ok", "semester": pretty_sem, "table": table_name, "count": len(events), "config_updates": config_updates}
    except Exception as e:
        logging.exception("_do_parse_calendar failed")
        return {"error": str(e)}

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

# ═══════════════════════════════════════════════════════════════════
#  PROFESSIONAL PDF GENERATION (EWUmatePDFEngine)
# ═══════════════════════════════════════════════════════════════════
from .ewumate_pdf_engine import EWUmatePDFEngine

def handle_generate_pdf(body):
    buffer = io.BytesIO()
    engine = EWUmatePDFEngine(buffer, body)
    engine.generate()
    buffer.seek(0)
    return buffer.read()

