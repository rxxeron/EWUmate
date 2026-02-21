"""
EWUmate Azure Functions — Supabase Backend
==========================================
Three main endpoints:
  POST /api/recalculate_stats     - CGPA + structured semester history
  POST /api/update_progress       - Live semester mark tracking → SGPA
  POST /api/generate_schedules    - Schedule generation (backtracking)
"""

import json
import logging
import os
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
        "recalculate_stats": handle_recalculate_stats,
        "update_progress": handle_update_progress,
        "generate_schedules": handle_generate_schedules,
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
#  1. RECALCULATE STATS  (CGPA, Semester History, Credits)
# ═══════════════════════════════════════════════════════════════════
import re

def _sem_sort_key(sem_str):
    """Sort key for semester strings like 'Spring2024', 'Fall 2025'."""
    m = re.search(r"(Spring|Summer|Fall)\s*(\d{4})", sem_str, re.IGNORECASE)
    if not m:
        return (0, 0)
    term_order = {"spring": 1, "summer": 2, "fall": 3}
    return (int(m.group(2)), term_order.get(m.group(1).lower(), 0))


def handle_recalculate_stats(body: dict) -> dict:
    """
    Input:  { "user_id": "uuid" }
    
    Reads:
      - academic_data.semesters  (raw map: { "Spring2024": {"CSE101": "A+", ...}, ... })
      - course_metadata          (credit lookup)
      - profiles                 (program info for remained credits)
    
    Writes back to academic_data:
      - semesters   → structured list with credits, grade points, term GPA
      - cgpa
      - total_credits_earned
      - remained_credits
    """
    user_id = body.get("user_id")
    if not user_id:
        raise ValueError("user_id is required")

    sb = _get_supabase()

    # 1) Fetch raw course history
    acad = sb.table("academic_data").select("*").eq("user_id", user_id).maybe_single().execute()
    raw_semesters = None
    if acad.data:
        raw_semesters = acad.data.get("semesters")
    
    if not raw_semesters:
        return {"status": "no_data", "message": "No course history found"}

    # 2) Build credit + name lookup from course_metadata
    meta = sb.table("course_metadata").select("code, name, credits, credit_val").execute()
    credit_map = {}
    name_map = {}
    for row in (meta.data or []):
        code = (row.get("code") or "").upper().replace(" ", "")
        # Store course name
        name_map[code] = row.get("name") or code
        # prefer credit_val (INTEGER), fallback to credits (TEXT)
        val = row.get("credit_val")
        if val is None or val == "":
            val = row.get("credits") or "3"
        # credits column is TEXT type, so parse carefully
        try:
            parsed = float(str(val).strip())
            credit_map[code] = parsed if parsed > 0 else 3.0
        except (ValueError, TypeError):
            credit_map[code] = 3.0

    # 3) Normalize semesters to a common format: list of (sem_name, [(code, grade), ...])
    normalized = []
    if isinstance(raw_semesters, dict):
        # Map format from onboarding: {"Fall 2025": {"ICE109": "A+", ...}}
        for sem_name in sorted(raw_semesters.keys(), key=_sem_sort_key):
            courses_map = raw_semesters[sem_name]
            if not isinstance(courses_map, dict):
                continue
            pairs = [(c.upper().replace(" ", ""), g) for c, g in courses_map.items() if g is not None]
            normalized.append((sem_name, pairs))
    elif isinstance(raw_semesters, list):
        # List format from semester transition: [{"semesterName": "...", "courses": [{"code": "...", "grade": "..."}]}]
        items = []
        for item in raw_semesters:
            if not isinstance(item, dict):
                continue
            sem_name = item.get("semesterName", "")
            courses_list = item.get("courses", [])
            pairs = []
            for c in courses_list:
                code = (c.get("code") or c.get("courseCode") or "").upper().replace(" ", "")
                grade = c.get("grade", "")
                if code:
                    pairs.append((code, grade))
            if sem_name:
                items.append((sem_name, pairs))
        items.sort(key=lambda x: _sem_sort_key(x[0]))
        normalized = items
    else:
        return {"status": "no_data", "message": "Unrecognized semesters format"}

    # 4) Process normalized semesters
    cum_points = 0.0
    cum_credits = 0.0
    total_completed = 0
    semesters_list = []

    for sem_name, course_pairs in normalized:
        term_points = 0.0
        term_credits = 0.0
        term_courses = []

        for code, grade in course_pairs:
            if not grade:
                continue

            credits = credit_map.get(code, 3.0)
            gp = 0.0

            if grade in ("W", "I", ""):
                pass  # no points
            elif grade == "Ongoing":
                pass
            else:
                gp = GRADE_POINTS.get(grade, 0.0)
                term_points += gp * credits
                term_credits += credits
                if gp > 0:
                    total_completed += 1

            term_courses.append({
                "code": code,
                "title": name_map.get(code, code),
                "credits": credits,
                "grade": grade,
                "point": gp,
            })

        term_gpa = (term_points / term_credits) if term_credits > 0 else 0.0
        cum_points += term_points
        cum_credits += term_credits
        cum_gpa = (cum_points / cum_credits) if cum_credits > 0 else 0.0

        semesters_list.append({
            "semesterName": sem_name,
            "termGPA": round(term_gpa, 2),
            "cumulativeGPA": round(cum_gpa, 2),
            "courses": term_courses,
        })

    cgpa = round((cum_points / cum_credits) if cum_credits > 0 else 0.0, 2)

    # 4) Determine total required credits from profile
    profile = sb.table("profiles").select("program_id").eq("id", user_id).maybe_single().execute()
    program = (profile.data or {}).get("program_id", "")
    total_required = _get_required_total(sb, program)
    remained = max(0.0, total_required - cum_credits)

    # 5) Write back structured data (only columns that exist in schema)
    sb.table("academic_data").upsert({
        "user_id": user_id,
        "semesters": semesters_list,      # NOW a structured list, not raw map
        "cgpa": cgpa,
        "total_credits_earned": round(cum_credits, 1),
        "remained_credits": round(remained, 1),
    }).execute()

    return {
        "status": "ok",
        "cgpa": cgpa,
        "total_credits": round(cum_credits, 1),
        "remained_credits": round(remained, 1),
        "semesters_count": len(semesters_list),
    }


def _get_required_total(sb, program_id: str) -> float:
    p_id = (program_id or "").lower().strip()
    if not p_id:
        return 140.0
        
    try:
        # Fetch from departments table where programs contains this ID
        # Note: The 'programs' column is a JSON array of objects
        res = sb.table("departments").select("programs").execute()
        if res.data:
            for dept in res.data:
                progs = dept.get("programs") or []
                for p in progs:
                    if p.get("id", "").lower() == p_id:
                        return float(p.get("credits", 140.0))
    except Exception as e:
        print(f"Error fetching credits for {p_id}: {e}")

    # Fallback to intelligent defaults if DB fetch fails
    if "cse" in p_id or "ice" in p_id:
        return 140.0
    if "eee" in p_id or "ete" in p_id:
        return 148.0
    if "pharma" in p_id or "pha" in p_id:
        return 160.0
    if "bba" in p_id or "mba" in p_id:
        return 123.0
    return 140.0  # default


# ═══════════════════════════════════════════════════════════════════
#  2. UPDATE SEMESTER PROGRESS  (Live marks → predicted grade)
# ═══════════════════════════════════════════════════════════════════
def _predict_grade(percentage: float):
    if percentage >= 80: return "A+", 4.00
    if percentage >= 75: return "A", 3.75
    if percentage >= 70: return "A-", 3.50
    if percentage >= 65: return "B+", 3.25
    if percentage >= 60: return "B", 3.00
    if percentage >= 55: return "B-", 2.75
    if percentage >= 50: return "C+", 2.50
    if percentage >= 45: return "C", 2.25
    if percentage >= 40: return "D", 2.00
    return "F", 0.00


def _calculate_course_score(course_data: dict):
    """Calculate total obtained, max, percentage for one course."""
    distribution = course_data.get("distribution", {})
    obtained = course_data.get("obtained", {})
    config = course_data.get("markConfig", {})

    total_obtained = 0.0
    total_max = 0.0
    breakdown = []

    for component, weight in distribution.items():
        if weight is None:
            continue
        weight = float(weight)
        val = obtained.get(component)

        comp_max = weight
        comp_obtained = 0.0

        if isinstance(val, list):
            list_val = [float(x) for x in val if x is not None]
            if list_val:
                comp_config = config.get(component, {})
                strategy = comp_config.get("strategy", "average")
                out_of = float(comp_config.get("outOf", 10.0))

                if strategy == "bestN":
                    n = int(comp_config.get("n", 1))
                    best = sorted(list_val, reverse=True)[:n]
                    avg_raw = sum(best) / len(best)
                    comp_obtained = (avg_raw / out_of) * weight
                elif strategy == "average":
                    avg_raw = sum(list_val) / len(list_val)
                    comp_obtained = (avg_raw / out_of) * weight
                elif strategy == "sum":
                    scale = float(comp_config.get("scaleFactor", 1.0))
                    if "scaleFactor" not in comp_config and out_of > 0:
                        total_n = int(comp_config.get("totalN", len(list_val)))
                        if total_n > 0:
                            scale = weight / (total_n * out_of)
                    comp_obtained = sum(list_val) * scale
                else:
                    comp_obtained = (sum(list_val) / len(list_val)) if list_val else 0.0
        else:
            comp_obtained = float(val) if val is not None else 0.0

        comp_obtained = min(comp_obtained, comp_max)
        total_obtained += comp_obtained
        total_max += comp_max
        breakdown.append({
            "name": component,
            "max": comp_max,
            "obtained": round(comp_obtained, 2),
        })

    pct = (total_obtained / total_max * 100) if total_max > 0 else 0.0
    return total_obtained, total_max, pct, breakdown


def handle_update_progress(body: dict) -> dict:
    """
    Input:  { "user_id": "uuid", "semester_code": "Spring2026" }
    
    Reads semester_progress.summary.courses for that user+semester,
    calculates predicted SGPA, writes back summary.
    """
    user_id = body.get("user_id")
    semester_code = body.get("semester_code")
    if not user_id or not semester_code:
        raise ValueError("user_id and semester_code are required")

    sb = _get_supabase()

    # 1) Fetch semester progress row
    row = (sb.table("semester_progress")
           .select("*")
           .eq("user_id", user_id)
           .eq("semester_code", semester_code)
           .maybe_single()
           .execute())

    if not row.data:
        return {"status": "no_data", "message": "No semester progress found"}

    summary = row.data.get("summary", {})
    courses_map = summary.get("courses", {})

    if not courses_map:
        return {"status": "no_courses"}

    # 2) Build credit lookup
    meta = sb.table("course_metadata").select("code, credits, credit_val").execute()
    credit_map = {}
    for r in (meta.data or []):
        code = (r.get("code") or "").upper().replace(" ", "")
        val = r.get("credit_val") or r.get("credits") or 3
        try:
            credit_map[code] = float(val)
        except (ValueError, TypeError):
            credit_map[code] = 3.0

    # 3) Calculate each course
    total_gp_credits = 0.0
    total_credits = 0.0
    course_summaries = []

    for code, course_data in courses_map.items():
        clean_code = code.upper().replace(" ", "")
        credits = credit_map.get(clean_code, 3.0)

        obtained, max_pts, pct, breakdown = _calculate_course_score(course_data)
        grade, gpa = _predict_grade(pct)

        total_gp_credits += gpa * credits
        total_credits += credits

        course_summaries.append({
            "courseCode": clean_code,
            "credits": credits,
            "percentage": round(pct, 2),
            "grade": grade,
            "gpa": gpa,
            "obtained": round(obtained, 2),
            "max": round(max_pts, 2),
            "breakdown": breakdown,
        })

    sgpa = round((total_gp_credits / total_credits) if total_credits > 0 else 0.0, 2)

    # 4) Write back
    summary["sgpa"] = sgpa
    summary["totalCredits"] = total_credits
    summary["courseSummaries"] = course_summaries

    sb.table("semester_progress").upsert({
        "user_id": user_id,
        "semester_code": semester_code,
        "summary": summary,
    }).execute()

    return {"status": "ok", "sgpa": sgpa, "courses": len(course_summaries)}


# ═══════════════════════════════════════════════════════════════════
#  3. SCHEDULE GENERATION  (Backtracking)
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
        return None, None, None
    sem = match.group(1).capitalize()
    year = match.group(2)
    return f"{sem}{year}", f"{sem} {year}", filename

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
    sem_code, pretty_sem, filename = _get_semester_from_path(file_path)
    if not sem_code: return {"error": f"Semester not found in filename: {file_path}"}
    
    table_name = f"courses_{sem_code.lower()}"
    sb = _get_supabase()

    try:
        res = sb.storage.from_("academic_documents").download(file_path)
        pdf_bytes = io.BytesIO(res)
        
        meta_res = sb.table("course_metadata").select("code, name, credits, credit_val").execute()
        course_titles = { (r.get("code") or "").upper().replace(" ", ""): r for r in (meta_res.data or []) }
        
        courses = course_parser.parse_course_pdf(pdf_bytes, sem_code, course_titles=course_titles)
        if not courses: return {"status": "warning", "message": "No courses found."}
        
        # Create table if it doesn't exist (idempotent RPC)
        sb.rpc("create_course_table", {"p_semester_code": sem_code}).execute()
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
    sem_code, pretty_sem, filename = _get_semester_from_path(file_path)
    # Note: Calendar usually contains semester IN content, but we use filename as backup
    
    sb = _get_supabase()
    try:
        res = sb.storage.from_("academic_documents").download(file_path)
        pdf_bytes = io.BytesIO(res)
        
        parsed = calendar_parser.parse_calendar_pdf(pdf_bytes)
        events = parsed.get("events", [])
        metadata = parsed.get("metadata", {})
        
        detected_sem = metadata.get("currentSemester")
        if detected_sem:
            # Normalize detected semester if possible
            match = re.search(r"(Spring|Summer|Fall)\s*(\d{4})", detected_sem, re.IGNORECASE)
            if match:
                sem_code = f"{match.group(1).capitalize()}{match.group(2)}"
                pretty_sem = f"{match.group(1).capitalize()} {match.group(2)}"
        
        if not sem_code: return {"error": "Semester not detected from filename or content."}
        table_name = f"calendar_{sem_code.lower()}"
        
        sb.rpc("create_calendar_table", {"p_semester_code": sem_code}).execute()
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
        config_updates = _update_semester_config(sb, detected_sem, metadata, events=events)
        
        return {"status": "ok", "semester": pretty_sem, "table": table_name, "count": len(events), "config_updates": config_updates}
    except Exception as e:
        logging.exception("_do_parse_calendar failed")
        return {"error": str(e)}

def _update_semester_config(sb, detected_semester, metadata, events=None):
    """
    Updates the dedicated 'active_semester' table with:
    - Current/Next Semester (Pretty & Code)
    - Upcoming Start Date
    - Online Advising Start Date
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
        
        # 2. Fetch existing config
        existing = sb.table("active_semester").select("*").eq("id", 1).maybe_single().execute()
        existing_data = existing.data if existing else None
        existing_curr_code = existing_data.get("current_semester_code") if existing_data else None

        # 3. Extract milestones (Picking earliest dates found)
        advising_start_date = None
        classes_start_date = None
        
        for evt in events:
            evt_name = evt.get("name", "").lower()
            evt_date = evt.get("date")
            if not evt_date: continue

            if "online advising" in evt_name or "advising of courses" in evt_name:
                if not advising_start_date or evt_date < advising_start_date:
                    advising_start_date = evt_date

            if "first day of classes" in evt_name or "classes begin" in evt_name:
                if not classes_start_date or evt_date < classes_start_date:
                    classes_start_date = evt_date

        # 4. Integrate Metadata from Parser (High Precision)
        meta = metadata or {}
        
        # 5. Decide what to update
        payload = {"id": 1, "is_active": True, "updated_at": _dt.now().isoformat()}
        
        is_early_upload = False
        if curr_code and existing_curr_code and curr_code != existing_curr_code:
            is_early_upload = True
            
        logging.info(f"Semester Sync: Detected={curr_code}, Existing={existing_curr_code}, is_early={is_early_upload}")

        if is_early_upload:
            payload["next_semester"] = curr_sem
            payload["next_semester_code"] = curr_code
            
            # Map precise metadata for NEXT semester
            payload["upcoming_semester_start_date"] = meta.get("upcomingSemesterStartDate")
            payload["switch_date"] = meta.get("switchDate")
            payload["grade_submission_start"] = meta.get("gradeSubmissionStart")
            payload["grade_submission_deadline"] = meta.get("gradeSubmissionDeadline")
            payload["advising_start_date"] = meta.get("advisingStartDate")
        else:
            payload["current_semester"] = curr_sem
            payload["current_semester_code"] = curr_code
            
            # For current semester, update the start date if found
            if meta.get("currentSemesterStartDate"):
                payload["current_semester_start_date"] = meta.get("currentSemesterStartDate")

            # **[Always save impending semester metadata if available in the text block]**
            if meta.get("nextSemester"):
                 payload["next_semester"] = meta.get("nextSemester")
                 match = re.search(r"(Spring|Summer|Fall)\s*(\d{4})", meta.get("nextSemester"), re.IGNORECASE)
                 if match: payload["next_semester_code"] = f"{match.group(1).capitalize()}{match.group(2)}"
                 
            if meta.get("upcomingSemesterStartDate"):
                 payload["upcoming_semester_start_date"] = meta.get("upcomingSemesterStartDate")

            # Fallback/Update advising if found in current calendar
            if meta.get("advisingStartDate"):
                 payload["advising_start_date"] = meta.get("advisingStartDate")

            # Update windows if they are from the current calendar and missing
            if not existing_data or not existing_data.get("grade_submission_deadline"):
                 payload["grade_submission_start"] = meta.get("gradeSubmissionStart")
                 payload["grade_submission_deadline"] = meta.get("gradeSubmissionDeadline")
                 payload["switch_date"] = meta.get("switchDate")
            
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
    sem_code, pretty_sem, filename = _get_semester_from_path(file_path)
    if not sem_code: return {"error": f"Semester not found in filename: {file_path}"}
    
    table_name = f"exams_{sem_code.lower()}"
    sb = _get_supabase()

    try:
        res = sb.storage.from_("academic_documents").download(file_path)
        pdf_bytes = io.BytesIO(res)
        
        exams = exam_parser.parse_exam_pdf(pdf_bytes, sem_code)
        if not exams: return {"status": "warning", "message": "No exam mappings found."}
        
        # Create table if it doesn't exist (idempotent RPC)
        sb.rpc("create_exam_table", {"p_semester_code": sem_code}).execute()
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
            req_data = json.dumps({"semester": sem_code.lower()}).encode("utf-8")
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
    sem_code, pretty_sem, filename = _get_semester_from_path(file_path)
    if not sem_code: return {"error": f"Semester not found in filename: {file_path}"}
    
    table_name = f"advising_{sem_code.lower()}"
    sb = _get_supabase()

    try:
        res = sb.storage.from_("academic_documents").download(file_path)
        
        if filename.lower().endswith(".eml"):
            slots = advising_parser.parse_advising_eml(res, sem_code)
        else:
            return {"error": "Only .eml files are supported for advising schedule for now."}
            
        if not slots: return {"status": "warning", "message": "No advising slots found."}
        
        # Create table if it doesn't exist (idempotent RPC)
        sb.rpc("create_advising_table", {"p_semester_code": sem_code}).execute()
        # Clear ALL existing data (table is per-semester, no filter needed)
        sb.table(table_name).delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
        
        for i in range(0, len(slots), 100):
            sb.table(table_name).insert(slots[i:i+100]).execute()
            
        return {"status": "ok", "semester": pretty_sem, "table": table_name, "count": len(slots)}
    except Exception as e:
        logging.exception("_do_parse_advising failed")
        return {"error": str(e)}
