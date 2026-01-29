
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

def _get_sorted_semesters(semester_keys):
    """Sorts semester keys chronologically (Spring, Summer, Fall)."""
    
    SEMESTER_ORDER = {"Spring": 1, "Summer": 2, "Fall": 3}

    def sort_key(semester_str):
        try:
            name, year_str = semester_str.split()
            year = int(year_str)
            return (year, SEMESTER_ORDER.get(name, 4))
        except (ValueError, IndexError):
            # Fallback for malformed semester strings
            return (0, 0)

    return sorted(semester_keys, key=sort_key)


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
        user_doc = event.data.after
        
        if not user_doc or not user_doc.exists:
            print("User deleted or invalid snapshot.")
            return

        data = user_doc.to_dict()
        uid = event.params['userId']
        
        print(f"Starting academic calc for {uid}...")

        # 1. Fetch Configuration & Metadata
        current_sem_fallback = "Unknown"
        metadata_map = {}
        try:
             app_info = db.collection('config').document('app_info').get()
             if app_info.exists:
                 current_sem_fallback = app_info.to_dict().get('currentSemester', 'Unknown')
             
             meta_doc = db.collection('metadata').document('courses').get()
             if meta_doc.exists:
                 meta_data = meta_doc.to_dict()
                 if "list" in meta_data and isinstance(meta_data["list"], list):
                     for item in meta_data["list"]:
                         if isinstance(item, dict):
                             key = item.get('id', item.get('code'))
                             if key:
                                 metadata_map[key] = item
        except Exception as e:
            print(f"Warning: Could not fetch metadata. {e}")


        # 2. Extract Data
        course_history = data.get('courseHistory', {})
        enrolled_sections = data.get('enrolledSections', [])
        program_id = data.get('programId', 'N/A')

        # 3. Calculate Completed Courses (History)
        total_points = 0.0
        total_credits = 0.0
        courses_completed = 0
        remained_credits = 140.0
        
        final_semester_map = {}

        if course_history and isinstance(course_history, dict):
            # Sort semesters to process them in chronological order
            sorted_semesters = _get_sorted_semesters(course_history.keys())

            for semester in sorted_semesters:
                courses = course_history[semester]
                if not isinstance(courses, dict): continue
                
                if semester not in final_semester_map:
                    final_semester_map[semester] = []

                for code, grade in courses.items():
                    if grade in ["Ongoing", "W", "I", ""]: 
                        continue

                    # Determine credits for the course
                    credits = 3.0
                    if code in metadata_map and 'creditVal' in metadata_map[code]:
                         credits = float(metadata_map[code]['creditVal'])
                    else:
                         credits = MASTER_CREDITS.get(code, 3.0)
                    
                    # Get grade points
                    gp = GRADE_POINTS.get(grade, 0.0)
                    
                    # Accumulate totals
                    total_points += (gp * credits)
                    total_credits += credits
                    if gp > 0:
                        courses_completed += 1
                        
                    # Add to the semester map for detailed profile
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
                parts = section_id.split('_')
                code = ""
                sem = current_sem_fallback
                
                if section_id.startswith("course_") and len(parts) >= 2:
                    code = parts[1]
                elif len(parts) >= 3:
                     code = parts[0]
                     sem = parts[2]
                
                if not code: continue

                if sem not in final_semester_map:
                    final_semester_map[sem] = []
                
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
        
        remained = max(0.0, remained_credits - total_credits)
        
        # 6. Resolve Program Name
        program_name = _resolve_program_name(program_id, db)

        # 7. Write Result 1: Statistics on User Doc (for Dashboard)
        user_doc.reference.set({
            "statistics": {
                "cgpa": round(cgpa, 2),
                "totalCredits": round(total_credits, 1),
                "coursesCompleted": courses_completed,
                "remainedCredits": round(remained, 1),
                "lastUpdated": firestore.SERVER_TIMESTAMP
            },
            "scholarshipStatus": _calculate_scholarship(course_history, metadata_map)
        }, merge=True)

        # 8. Write Result 2: Detailed Profile (for Degree Progress)
        profile_list = []
        cumulative_credits = 0.0
        cumulative_points = 0.0

        sorted_profile_semesters = _get_sorted_semesters(final_semester_map.keys())

        for sem_name in sorted_profile_semesters:
            courses = final_semester_map[sem_name]
            term_points = sum(c['point'] * c['credits'] for c in courses if c['grade'] != "Ongoing")
            term_credits = sum(c['credits'] for c in courses if c['grade'] != "Ongoing")
            
            term_gpa = 0.0
            if term_credits > 0:
                term_gpa = term_points / term_credits

            cumulative_credits += term_credits
            cumulative_points += term_points
            
            current_cumulative_gpa = 0.0
            if cumulative_credits > 0:
                current_cumulative_gpa = cumulative_points / cumulative_credits

            profile_list.append({
                "semesterName": sem_name,
                "semesterId": sem_name.replace(" ", ""),
                "courses": courses,
                "termGPA": round(term_gpa, 2),
                "cumulativeGPA": round(current_cumulative_gpa, 2) 
            })

        db.collection("users").document(uid).collection("academic_data").document("profile").set({
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
    
    if db:
        try:
            depts_doc = db.collection('metadata').document('departments').get()
            if depts_doc.exists:
                data = depts_doc.to_dict()
                items = []
                if isinstance(data, dict):
                    items = data.values()
                elif isinstance(data, list):
                    items = data
                
                for dept in items:
                    if not isinstance(dept, dict): continue
                    programs = dept.get('programs', [])
                    
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
    
    return pid.upper()

def _calculate_scholarship(course_history, metadata_map):
    """
    Calculates scholarship based on the last 3 completed semesters.
    """
    if not course_history or not isinstance(course_history, dict):
        return "N/A"

    # Get a list of semesters that only contain completed courses
    completed_semesters = []
    for sem, courses in course_history.items():
        if isinstance(courses, dict) and any(g not in ["Ongoing", "W", "I", ""] for g in courses.values()):
             completed_semesters.append(sem)
    
    # We need at least 3 completed semesters
    if len(completed_semesters) < 3:
        return "N/A"

    # Sort the completed semesters chronologically
    sorted_completed_semesters = _get_sorted_semesters(completed_semesters)
    
    # Get the last 3 semesters from the sorted list
    scholarship_semesters = sorted_completed_semesters[-3:]
    
    print(f"Scholarship calculation for semesters: {scholarship_semesters}")

    total_points = 0.0
    total_credits = 0.0

    # Calculate GPA for only these 3 semesters
    for semester in scholarship_semesters:
        courses = course_history.get(semester, {})
        for code, grade in courses.items():
            if grade in ["Ongoing", "W", "I", ""]:
                continue

            credits = 3.0
            if code in metadata_map and 'creditVal' in metadata_map[code]:
                credits = float(metadata_map[code]['creditVal'])
            else:
                credits = MASTER_CREDITS.get(code, 3.0)

            gp = GRADE_POINTS.get(grade, 0.0)
            
            total_points += gp * credits
            total_credits += credits

    if total_credits == 0:
        return "N/A"
        
    scholarship_gpa = total_points / total_credits

    print(f"Scholarship GPA: {scholarship_gpa}, Credits Considered: {total_credits}")

    # Determine scholarship based on the GPA from the last 3 semesters
    if total_credits < 12:  # Assuming a minimum credit requirement per year
        return "Ineligible (Credits)"
    if scholarship_gpa >= 3.5:
        return "Merit Scholarship"
    
    return "No Scholarship"
