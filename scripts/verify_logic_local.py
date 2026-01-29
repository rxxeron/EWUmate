
import json

# --- MOCK DATA FROM USER ---
USER_DATA = {
  "admittedSemester": "Summer 2025",
  "programId": "ice",
  "enrolledSections": [
    "course_ICE107_12",
    "course_ICE204_14",
    "course_CHE109_6",
    "course_MAT102_4"
  ],
  "courseHistory": {
    "Fall 2025": {
      "ENG102": "A",
      "ICE109": "A+",
      "PHY109": "A"
    },
    "Summer 2025": {
      "ENG101": "A+",
      "ICE103": "A+",
      "MAT101": "A+"
    }
  }
}

# --- LOGIC TO TEST (Copied from academic_logic.py) ---
MASTER_CREDITS = {
    "ENG101": 3.0, "ENG102": 3.0, "MAT101": 3.0, "MAT102": 3.0,
    "PHY109": 3.0, "CHE109": 3.0, "CSE101": 3.0, "CSE102": 3.0,
    "ICE103": 3.0, "ICE109": 3.0, "ICE107": 3.0, "ICE204": 3.0 # Added some implied ones
}

GRADE_POINTS = {
    "A+": 4.0, "A": 4.0, "A-": 3.7,
    "B+": 3.3, "B": 3.0, "B-": 2.7,
    "C+": 2.3, "C": 2.0, "C-": 1.7,
    "D+": 1.3, "D": 1.0, "F": 0.0
}

def resolve_program_name(pid):
    if not pid: return "Unknown Program"
    pid = pid.lower().strip()
    mapping = {
        "ice": "B.Sc. in Information & Communication Engineering",
    }
    return mapping.get(pid, pid.upper())

def run_calculation():
    print("Running Calculation on Mock Data...")
    
    course_history = USER_DATA.get('courseHistory', {})
    enrolled_sections = USER_DATA.get('enrolledSections', [])
    program_id = USER_DATA.get('programId', 'N/A')
    
    total_points = 0.0
    total_credits = 0.0
    courses_completed = 0
    remained_credits = 140.0
    
    final_semester_map = {}
    
    # 1. Process History
    if course_history and isinstance(course_history, dict):
        for semester, courses in course_history.items():
            if not isinstance(courses, dict): continue
            
            if semester not in final_semester_map:
                final_semester_map[semester] = []
                
            for code, grade in courses.items():
                credits = MASTER_CREDITS.get(code, 3.0)
                gp = GRADE_POINTS.get(grade, 0.0)
                
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

    # 2. Process Enrolled
    current_sem_fallback = "Spring 2026" # Mock current sem
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
            
            if sem not in final_semester_map: final_semester_map[sem] = []
            
            # check dupes
            if any(c['code'] == code for c in final_semester_map[sem]): continue
            
            credits = MASTER_CREDITS.get(code, 3.0)
            
            final_semester_map[sem].append({
                    "code": code,
                    "grade": "Ongoing",
                    "point": 0.0,
                    "credits": credits,
                    "status": "Ongoing"
            })

    # 3. Final Stats
    cgpa = 0.0
    if total_credits > 0:
        cgpa = total_points / total_credits
        
    program_name = resolve_program_name(program_id)
    
    print("\n--- RESULTS ---")
    print(f"Program Name: {program_name}")
    print(f"CGPA: {cgpa:.2f}")
    print(f"Total Credits: {total_credits}")
    print(f"Courses Completed: {courses_completed}")
    print(f"Semesters Parsed: {list(final_semester_map.keys())}")
    
    # Check Enrolled
    spring_26 = final_semester_map.get("Spring 2026", [])
    print(f"Spring 2026 Courses ({len(spring_26)}): {[c['code'] for c in spring_26]}")

if __name__ == "__main__":
    run_calculation()
