
import json
import os
import sys
import importlib.util
from datetime import datetime as _dt

def import_module_from_path(module_name, file_path):
    spec = importlib.util.spec_from_file_location(module_name, file_path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module

def simulate_active_semester_payload(result, semester_type):
    events = result.get("events", [])
    meta = result.get("metadata", {})
    
    advising_start = None
    classes_start = None
    grades_start = None
    grades_deadline = None
    u_reopens = None
    final_exam_start = None
    next_sem_start = None
    
    for evt in events:
        evt_name = evt.get("name", "").lower()
        evt_date = evt.get("date")
        if not evt_date or not isinstance(evt_date, str) or len(evt_date) < 10: continue

        if "online advising" in evt_name or "advising of courses" in evt_name:
            if not advising_start or evt_date < advising_start:
                advising_start = evt_date

        if "first day of classes" in evt_name or "classes begin" in evt_name:
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
        
        if "final exam" in evt_name or "final examination" in evt_name:
            if not final_exam_start or evt_date < final_exam_start:
                final_exam_start = evt_date

    payload = {
        "semester_type": semester_type,
        "is_active": True,
        "current_semester": meta.get("currentSemester"),
        "current_semester_code": meta.get("currentSemester", "").replace(" ", ""),
        "current_semester_start_date": meta.get("currentSemesterStartDate") or classes_start,
        "advising_start_date": meta.get("advisingStartDate") or advising_start,
        "advising_end_date": meta.get("advisingEndDate") or (meta.get("advisingStartDate") or advising_start),
        "grade_submission_start": meta.get("gradeSubmissionStart") or grades_start,
        "grade_submission_deadline": meta.get("gradeSubmissionDeadline") or grades_deadline,
        "final_exam_start": meta.get("finalExamStart") or final_exam_start,
        "final_exam_end": meta.get("finalExamEnd") or (meta.get("finalExamStart") or final_exam_start),
        "switch_date": meta.get("switchDate") or u_reopens,
        "updated_at": _dt.now().isoformat()
    }
    
    next_sem_meta = meta.get("nextSemester")
    if next_sem_meta:
        payload["next_semester"] = str(next_sem_meta)
        
    if meta.get("upcomingSemesterStartDate") or next_sem_start:
        payload["upcoming_semester_start_date"] = meta.get("upcomingSemesterStartDate") or next_sem_start
        
    return payload

def test_parse():
    parser_path = r"D:\EWUmate\EWUmate_Clean\azure_functions\ewumate_api\calendar_parser.py"
    calendar_parser = import_module_from_path("calendar_parser", parser_path)
    
    files = [
        {"path": r"D:\EWUmate\EWUmate_Clean\Academic Calendar Spring 2026 PHRM LLB.pdf", "type": "bi", "name": "spring_2026_phrm_llb"},
        {"path": r"D:\EWUmate\EWUmate_Clean\Academic Calender Spring 2026.pdf", "type": "tri", "name": "spring_2026"}
    ]
    
    output_dir = r"D:\EWUmate\EWUmate_Clean\azure_functions\test_outputs"
    os.makedirs(output_dir, exist_ok=True)
    
    for f_info in files:
        file_path = f_info["path"]
        if not os.path.exists(file_path): continue
            
        print(f"Parsing {os.path.basename(file_path)}...")
        try:
            with open(file_path, "rb") as f:
                result = calendar_parser.parse_calendar_pdf(f, filename=os.path.basename(file_path))
                
                # Save full result
                json_path = os.path.join(output_dir, f"calendar_{f_info['name']}.json")
                with open(json_path, "w") as jf:
                    json.dump(result, jf, indent=2)
                
                # Save simulated active_semester payload
                payload = simulate_active_semester_payload(result, f_info["type"])
                payload_path = os.path.join(output_dir, f"active_semester_{f_info['name']}.json")
                with open(payload_path, "w") as pf:
                    json.dump(payload, pf, indent=2)
                
                print(f"  Extracted {len(result['events'])} events.")
                print(f"  Saved JSON to: {json_path}")
                print(f"  Saved Payload to: {payload_path}")
                
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    test_parse()
