import firebase_admin
from firebase_admin import firestore
from firebase_functions import firestore_fn
import math

# Standard Credit Map (Fallback if not in history)
MASTER_CREDITS = {
    "ENG101": 3.0, "ENG102": 3.0, "MAT101": 3.0, "MAT102": 3.0,
    "PHY109": 3.0, "CHE109": 3.0, "CSE101": 3.0, "CSE102": 3.0
}

# Grade Points (Official Scale)
GRADE_POINTS = {
    "A+": 4.00, "A": 3.75, "A-": 3.50,
    "B+": 3.25, "B": 3.00, "B-": 2.75,
    "C+": 2.50, "C": 2.25, "D": 2.00, "F": 0.00
}

@firestore_fn.on_document_written(document="users/{userId}")
def calculate_academic_stats(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Cloud Function triggered on User Update to calculate academic stats.
    - CGPA
    - Total Credits
    - Program Name
    - Enrolled (Ongoing) Courses
    - Generates 'academic_data/profile' document for the UI.
    """
    try:
        db = firestore.client()
        # Handle 'after' snapshot for Create/Update
        user_doc = event.data.after
        
        if not user_doc or not user_doc.exists:
            print("User deleted or invalid snapshot.")
            return

        data = user_doc.to_dict()
        uid = event.params['userId']
        
        # Avoid infinite loop: Check if this update was just the stats/profile write
        # We can check 'lastTouch' vs 'lastUpdated' but simpler to just run idempotent.
        # However, to be safe, if the update only changed 'statistics' or 'academic_data', we should skip?
        # But 'statistics' is IN this doc.
        # Let's rely on idempotent calculation.
        
        print(f"Starting academic calc for {uid}...")

        # 1. Fetch Configuration & Metadata
        current_sem_fallback = "Unknown"
        metadata_map = {}
        try:
             # Fetch Semester Config
             app_info = db.collection('config').document('app_info').get()
             if app_info.exists:
                 current_sem_fallback = app_info.to_dict().get('currentSemester', 'Unknown')
             
             # Fetch Course Metadata for Credits
             meta_doc = db.collection('metadata').document('courses').get()
             if meta_doc.exists:
                 meta_data = meta_doc.to_dict()
                 # Support both Map {"CSE101": {...}} and List {"list": [...]}
                 if "list" in meta_data and isinstance(meta_data["list"], list):
                     for item in meta_data["list"]:
                         if isinstance(item, dict):
                             # Use 'id' or 'code' as the key
                             key = item.get('id', item.get('code'))
                             if key:
                                 metadata_map[key] = item
                 else:
                     # Assume map format if needed, or mix
                     pass
        except:
            pass

        # 2. Extract Data
        course_history = data.get('courseHistory', {}) # Map<Semester, Map<Code, Grade>>
        enrolled_sections = data.get('enrolledSections', []) # List<String>
        program_id = data.get('programId', 'N/A')

        # 3. Calculate Completed Courses (History)
        total_points = 0.0
        total_credits = 0.0
        courses_completed = 0
        remained_credits = 140.0 # Default total needed
        
        final_semester_map = {} # { "Spring 2025": [ {code, grade, ...} ] }

        if course_history and isinstance(course_history, dict):
            for semester, courses in course_history.items():
                if not isinstance(courses, dict): continue
                
                if semester not in final_semester_map:
                    final_semester_map[semester] = []

                for code, grade in courses.items():
                    # Skip non-grades
                    if grade in ["Ongoing", "W", "I", ""]: 
                        continue

                    # Determine Credits
                    # Priority: Metadata > Master Map > Default 3.0
                    credits = 3.0
                    if code in metadata_map and 'creditVal' in metadata_map[code]:
                         credits = float(metadata_map[code]['creditVal'])
                    else:
                         credits = MASTER_CREDITS.get(code, 3.0)
                    
                    # Calculate Point
                    gp = GRADE_POINTS.get(grade, 0.0)

                    
                    # Add to totals (only if not F? Standard GPA rules usually include F in attempt but 0 points)
                    # For simplify: If F, credits counted in attempt? 
                    # Let's assume standard: Attempted credits count.
                    
                    total_points += (gp * credits)
                    total_credits += credits
                    if gp > 0:
                        courses_completed += 1
                        
                    final_semester_map[semester].append({
                        "code": code,
                        "grade": grade,
                        "point": gp,
                        "credits": credits,
                        "status": "Completed"
                    })

        # 4. Process Ongoing (Enrolled)
        if enrolled_sections:
            for section_id in enrolled_sections:
                # Robust Parsing
                # Formats: 
                # 1. course_CODE_SECTION (App Format) -> course_ICE107_12
                # 2. CODE_SECTION_SEM (Standard) -> ICE107_12_Spring2026
                
                parts = section_id.split('_')
                code = ""
                sem = current_sem_fallback
                
                if section_id.startswith("course_") and len(parts) >= 2:
                    code = parts[1] # ICE107
                    # sem remains proper current semester
                elif len(parts) >= 3:
                     # Assume Format 2
                     code = parts[0]
                     sem = parts[2]
                
                if not code: continue

                # Add to map
                if sem not in final_semester_map:
                    final_semester_map[sem] = []
                
                # Avoid duplicates if already in history (e.g. re-taking)
                # But Ongoing is usually new.
                
                # Check if already added this run
                existing = [c['code'] for c in final_semester_map[sem]]
                if code in existing: continue
                
                final_semester_map[sem].append({
                    "code": code,
                    "grade": "Ongoing",
                    "point": 0.0,
                    "credits": MASTER_CREDITS.get(code, 3.0),
                    "status": "Ongoing"
                })

        # 5. Final Stats
        cgpa = 0.0
        if total_credits > 0:
            cgpa = total_points / total_credits
        
        remained = max(0.0, remained_credits - total_credits) # Approx
        
        # 6. Resolve Program Name
        program_name = _resolve_program_name(program_id, db)

        # 7. Write Result 1: Statistics on User Doc (for Dashboard)
        user_ref.set({
            "statistics": {
                "cgpa": round(cgpa, 2),
                "totalCredits": round(total_credits, 1),
                "coursesCompleted": courses_completed,
                "remainedCredits": round(remained, 1),
                "lastUpdated": firestore.SERVER_TIMESTAMP
            },
            "scholarshipStatus": _calculate_scholarship(cgpa, total_credits)
        }, merge=True)

        # 8. Write Result 2: Detailed Profile (for Degree Progress)
        # Convert map to list for UI
        profile_list = []
        for sem_name, courses in final_semester_map.items():
            # Calculate Term GPA
            term_points = sum(c['point'] * c['credits'] for c in courses if c['grade'] != "Ongoing")
            term_credits = sum(c['credits'] for c in courses if c['grade'] != "Ongoing")
            term_gpa = 0.0
            if term_credits > 0:
                term_gpa = term_points / term_credits
                
            profile_list.append({
                "semesterName": sem_name,
                "semesterId": sem_name.replace(" ", ""),
                "courses": courses,
                "termGPA": round(term_gpa, 2),
                "cumulativeGPA": 0.0 # UI calculates or we can? 
                # Note: Cumulative per semester is hard without strict ordering. 
                # UI 'results_repository' often relies on overall CGPA.
            })

        # Write Profile Doc
        db.collection("users").document(uid)\
          .collection("academic_data").document("profile")\
          .set({
              "semesters": profile_list, 
              "programName": program_name,
              "cgpa": round(cgpa, 2),
              "totalCreditsEarned": round(total_credits, 1),
              "totalCoursesCompleted": courses_completed,
              "remainedCredits": round(remained, 1),
              "lastUpdated": firestore.SERVER_TIMESTAMP
          })
          
        print(f"Stats Calculated: {cgpa} CGPA, {courses_completed} Courses")

    except Exception as e:
        print(f"Error in calculate_academic_stats: {e}")

def _resolve_program_name(pid, db=None):
    if not pid: return "Unknown Program"
    pid = pid.lower().strip()
    
    # 1. Try Metadata Lookup (if db provided)
    if db:
        try:
            depts_doc = db.collection('metadata').document('departments').get()
            if depts_doc.exists:
                data = depts_doc.to_dict()
                # Metadata structure: "departments": [ { "programs": { "0": { "id": "cse", "name": "..." } } } ] 
                # OR direct map if refactored. Based on screenshot:
                # "departments" seems to be a collection or list in 'departments' doc?
                # Screenshot shows: document 'departments' in 'metadata' collection.
                # Fields: 0: { name: "...", programs: [ {id: "cse", name: "..."} ] }
                
                # Check if 'departments' is a list or fields 0, 1 etc.
                # Usually it's a map mimicking list if imported from JSON.
                
                # Let's iterate values if it's a map-as-list
                items = []
                if isinstance(data, dict):
                    # Sort by keys if possible, or just values
                    items = data.values()
                elif isinstance(data, list):
                    items = data
                
                for dept in items:
                    if not isinstance(dept, dict): continue
                    programs = dept.get('programs', [])
                    
                    # Programs might be map or list
                    p_items = []
                    if isinstance(programs, dict):
                        p_items = programs.values()
                    elif isinstance(programs, list):
                        p_items = programs
                        
                    for p in p_items:
                        if not isinstance(p, dict): continue
                        p_id = p.get('id', '').lower()
                        if p_id == pid:
                            return p.get('name', pid)
                            
        except Exception as e:
            print(f"Metadata lookup failed: {e}")

    # 2. Hardcoded Fallback
    mapping = {
        "cse": "B.Sc. in Computer Science & Engineering",
        "ice": "B.Sc. in Information & Communication Engineering",
        "eee": "B.Sc. in Electrical & Electronic Engineering",
        "ete": "B.Sc. in Electronics & Telecommunication Engineering",
        "bba": "Bachelor of Business Administration",
        "pha": "Bachelor of Pharmacy",
        "eng": "B.A. in English",
        "eco": "B.S.S. in Economics",
        "geb": "B.Sc. in Genetic Engineering & Biotechnology"
    }
    
    for key, name in mapping.items():
        if key == pid: return name
    
    return pid.upper() # Return ID if all else fails # Fallback

def _calculate_scholarship(cgpa, credits):
    if credits < 12: return "N/A"
    if cgpa >= 3.5: return "Merit Scholarship"
    return "No Scholarship"
