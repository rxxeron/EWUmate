import azure.functions as func
import json
import logging
import sys
import os

# Import shared logic from the sibling package
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from ewumate_api import _do_parse_faculty, _do_parse_calendar, _do_parse_exam, _do_parse_advising


def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    Dedicated webhook endpoint for Supabase storage events.
    URL: POST /api/webhooks/storage

    Routing table (folder → handler):
    ┌─────────────────────┬──────────────────────────────┬─────────────────────────┐
    │ Folder              │ File pattern                 │ Handler                 │
    ├─────────────────────┼──────────────────────────────┼─────────────────────────┤
    │ facultylist/        │ Spring 2026.pdf              │ _do_parse_faculty       │
    │ calendar/           │ Academic Calendar Spring ... │ handle_parse_calendar   │
    │ examschedule/       │ Exam Schedule Spring ...     │ handle_parse_exam (TBD) │
    │ advisingschedule/   │ Advising Schedule Spring ... │ handle_parse_advising   │
    └─────────────────────┴──────────────────────────────┴─────────────────────────┘
    Both INSERT (new file) and UPDATE (re-upload same name) events are handled.
    """
    logging.info("Supabase storage webhook triggered.")

    try:
        body = req.get_json()
    except Exception:
        return func.HttpResponse(
            json.dumps({"error": "Invalid JSON body"}),
            status_code=400, mimetype="application/json"
        )

    event_type = body.get("type", "")
    record = body.get("record") or {}
    file_name = record.get("name", "")
    bucket_id = record.get("bucket_id", "")

    logging.info(f"Event: {event_type}, file: {file_name}, bucket: {bucket_id}")

    # Only handle INSERT or UPDATE (re-upload of same filename = UPDATE)
    if event_type not in ("INSERT", "UPDATE"):
        return func.HttpResponse(
            json.dumps({"status": "skipped", "reason": f"Ignored event type: {event_type}"}),
            status_code=200, mimetype="application/json"
        )

    folder = file_name.split("/")[0].lower() if "/" in file_name else ""
    basename = os.path.basename(file_name)

    logging.info(f"Folder: '{folder}', File: '{basename}'")

    # ── Route 1: Faculty List ──────────────────────────────────────────
    if folder == "facultylist":
        logging.info(f"→ parse_faculty: {file_name}")
        try:
            result = _do_parse_faculty(file_name)
        except Exception as e:
            logging.exception("parse_faculty failed")
            result = {"error": str(e)}
        return func.HttpResponse(json.dumps(result), status_code=200, mimetype="application/json")

    # ── Route 2: Academic Calendar ─────────────────────────────────────
    if folder in ("calendar", "academiccalendar"):
        logging.info(f"→ parse_calendar: {file_name}")
        try:
            result = _do_parse_calendar(file_name)
        except Exception as e:
            logging.exception("parse_calendar failed")
            result = {"error": str(e)}
        return func.HttpResponse(json.dumps(result), status_code=200, mimetype="application/json")

    # ── Route 3: Exam Schedule ─────────────────────────────────────────
    if folder == "examschedule":
        logging.info(f"→ parse_exam: {file_name}")
        try:
            result = _do_parse_exam(file_name)
        except Exception as e:
            logging.exception("parse_exam failed")
            result = {"error": str(e)}
        return func.HttpResponse(json.dumps(result), status_code=200, mimetype="application/json")

    # ── Route 4: Advising Schedule ─────────────────────────────────────
    if folder == "advisingschedule":
        logging.info(f"→ parse_advising: {file_name}")
        try:
            result = _do_parse_advising(file_name)
        except Exception as e:
            logging.exception("parse_advising failed")
            result = {"error": str(e)}
        return func.HttpResponse(json.dumps(result), status_code=200, mimetype="application/json")

    # ── No route matched ───────────────────────────────────────────────
    return func.HttpResponse(
        json.dumps({"status": "skipped", "reason": f"No handler for folder: '{folder}' / file: '{basename}'"}),
        status_code=200, mimetype="application/json"
    )
