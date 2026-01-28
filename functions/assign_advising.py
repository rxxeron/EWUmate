
import firebase_admin
from firebase_admin import firestore
from datetime import datetime

# Valid departments map/list
KNOWN_DEPTS = ["CSE", "EEE", "ECE", "BBA", "ECO", "ENG", "SOC", "GEB", "PHR", "B.PHARM", "LAW", "MATH", "POP", "MPS", "IS", "PPHS", "ICE", "DSA", "CE"]

def parse_schedule_datetime(date_str, time_str):
    # date_str: "03 December 2025" or "01-02 December 2025"
    # time_str: "06:00 PM"
    
    clean_date = date_str.split("-")[0].strip() # "01" or "03 December 2025"
    
    # Check if we split a date range like "01-02"
    parts = date_str.split("-")
    if len(parts) > 1 and " " not in parts[0]: 
        last_part = parts[-1].strip() # "02 December 2025"
        suffix_parts = last_part.split(" ", 1)
        if len(suffix_parts) > 1:
            suffix = suffix_parts[1]
            clean_date = f"{clean_date} {suffix}"
            
    try:
        dt_date = datetime.strptime(clean_date, "%d %B %Y")
        minutes = parse_time_to_minutes(time_str)
        if minutes is None: return None
        return dt_date.replace(hour=minutes//60, minute=minutes%60)
    except Exception as e:
        print(f"Error parsing date {date_str} {time_str}: {e}")
        return None

def find_best_slot_for_user(credits_earned, department, all_slots):
    candidates = []
    
    for slot in all_slots:
        # Check Department
        if slot.get('allowedDepartments'):
            # If slot has restriction, user MUST match
            # Ensure case-insensitive or strict match logic
            if department not in slot['allowedDepartments']:
                continue
        
        # Check Credits
        min_c = float(slot.get('minCredits', 0))
        max_c = float(slot.get('maxCredits', 999))
        
        if credits_earned >= min_c and credits_earned <= max_c:
            dt = parse_schedule_datetime(slot['date'], slot['startTime'])
            if dt:
                candidates.append((dt, slot))
                
    if not candidates:
        return None
        
    # Sort by datetime (earliest first)
    candidates.sort(key=lambda x: x[0])
    return candidates[0][1]

def assign_slot_to_user(db, user_id):
    # 1. Get User Data
    user_ref = db.collection('users').document(user_id)
    doc = user_ref.get()
    if not doc.exists:
        return {"error": "User not found"}
    
    user_data = doc.to_dict()
    earned = float(user_data.get("creditsEarned", 0.0))
    dept = user_data.get("department", "").strip().upper()
    
    # 2. Get Current Semester
    app_info = db.collection('config').document('app_info').get()
    current_semester = "Unknown"
    if app_info.exists:
        current_semester = app_info.to_dict().get('currentSemester', '').replace(" ", "")
    
    if not current_semester:
        return {"error": "Current semester not configured."}

    # 3. Fetch Schedule from Firestore
    # Path: advising_schedules/{semester}/slots
    slots_ref = db.collection('advising_schedules').document(current_semester).collection('slots')
    slots_docs = slots_ref.stream()
    all_slots = [d.to_dict() for d in slots_docs]
    
    if not all_slots:
        return {"error": f"No advising schedule found for {current_semester}"}
    
    # 4. Find Best Slot
    best_slot = find_best_slot_for_user(earned, dept, all_slots)
    
    # 5. Update User
    if best_slot:
        # Save as advisingSlot_{Semester} so we have history/specifics
        field_name = f"advisingSlot_{current_semester}"
        user_ref.update({
            field_name: best_slot
        })
        return {"success": True, "slot": best_slot, "semester": current_semester}
    else:
        return {"success": False, "message": "No suitable slot found for your criteria."}
