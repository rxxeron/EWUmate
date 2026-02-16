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
    raw_semesters = {}
    if acad.data:
        raw_semesters = acad.data.get("semesters") or {}
    
    if not raw_semesters or not isinstance(raw_semesters, dict):
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

    # 3) Process semesters
    sorted_keys = sorted(raw_semesters.keys(), key=_sem_sort_key)

    cum_points = 0.0
    cum_credits = 0.0
    total_completed = 0
    semesters_list = []

    for sem_name in sorted_keys:
        courses_map = raw_semesters[sem_name]
        if not isinstance(courses_map, dict):
            continue

        term_points = 0.0
        term_credits = 0.0
        term_courses = []

        for code, grade in courses_map.items():
            if grade is None:
                continue

            clean_code = code.upper().replace(" ", "")
            credits = credit_map.get(clean_code, 3.0)
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
                "code": clean_code,
                "title": name_map.get(clean_code, clean_code),
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
    total_required = _get_required_total(program)
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


def _get_required_total(program: str) -> float:
    p = (program or "").upper()
    if "CSE" in p or "COMPUTER" in p or "ICE" in p:
        return 148.0
    if "EEE" in p or "ETE" in p:
        return 148.0
    if "PHARMA" in p or "PHA" in p:
        return 160.0
    if "BBA" in p or "MBA" in p:
        return 130.0
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


def _generate_schedules(sections_map, filters, limit=80):
    """Backtracking schedule generator."""
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


def handle_generate_schedules(body: dict) -> dict:
    """
    Input:  {
        "user_id": "uuid",
        "semester": "Spring2026",
        "courses": ["CSE101", "CSE311", ...],
        "filters": { "exclude_days": ["Friday"] }   // optional
    }
    
    Fetches sections from `courses` table, runs backtracking,
    saves results to `schedule_generations`, returns generation ID.
    """
    user_id = body.get("user_id")
    semester = body.get("semester", "").replace(" ", "")
    course_codes = body.get("courses", [])
    filters = body.get("filters", {})

    if not user_id or not semester or not course_codes:
        raise ValueError("user_id, semester, and courses are required")

    sb = _get_supabase()

    # 1) Fetch sections for each course
    sections_map = {}
    for code in course_codes:
        clean = code.upper().replace(" ", "")
        result = sb.table("courses").select("*").eq("semester", semester).eq("code", clean).execute()
        secs = result.data or []
        if not secs:
            raise ValueError(f"No sections found for {clean} in {semester}")
        
        # Normalize field names (Supabase uses snake_case)
        for s in secs:
            if "start_time" in s and "startTime" not in s:
                for sess in (s.get("sessions") or []):
                    if "start_time" in sess:
                        sess["startTime"] = sess.pop("start_time")
                    if "end_time" in sess:
                        sess["endTime"] = sess.pop("end_time")
        
        sections_map[clean] = secs

    # 2) Generate
    schedules = _generate_schedules(sections_map, filters, limit=80)

    if not schedules:
        raise ValueError("No valid schedule combinations found. Try adjusting filters or courses.")

    # 3) Convert to storable format
    combinations = []
    for i, sched in enumerate(schedules):
        combo = {
            "scheduleId": i,
            "sections": {str(j): sec for j, sec in enumerate(sched)},
        }
        combinations.append(combo)

    # 4) Save to schedule_generations
    import uuid
    gen_id = str(uuid.uuid4())

    sb.table("schedule_generations").upsert({
        "id": gen_id,
        "user_id": user_id,
        "semester": semester,
        "courses": course_codes,
        "filters": filters,
        "combinations": combinations,
        "status": "completed",
        "count": len(schedules),
    }).execute()

    return {
        "status": "ok",
        "generationId": gen_id,
        "count": len(schedules),
    }
