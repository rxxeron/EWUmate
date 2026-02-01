
from firebase_admin import firestore
import re

GRADE_POINTS = {
    "A+": 4.00, "A": 3.75, "A-": 3.50,
    "B+": 3.25, "B": 3.00, "B-": 2.75,
    "C+": 2.50, "C": 2.25, "D": 2.00, "F": 0.00
}

def calculate_course_score(course_data):
    """
    Calculates the total score and percentage for a course.
    Supports advanced strategies: bestN, average, sum, and scaling.
    """
    distribution = course_data.get("distribution", {})
    obtained = course_data.get("obtained", {})
    
    # Advanced Config (optional)
    # { "quizzes": {"strategy": "bestN", "n": 2, "outOf": 10}, ... }
    config = course_data.get("markConfig", {})
    
    total_obtained = 0.0
    total_max = 0.0
    component_breakdown = []

    # Map of components to their obtained values
    # Some are single floats (mid, final), some are lists (quizzes)
    for component, weight in distribution.items():
        if weight is None: continue
        weight = float(weight)
        val = obtained.get(component)
        
        comp_max = weight
        comp_obtained = 0.0
        
        if isinstance(val, list):
            # Complex component logic (Quizzes, etc.)
            list_val = [float(x) for x in val if x is not None]
            if not list_val:
                comp_obtained = 0.0
            else:
                comp_config = config.get(component, {})
                strategy = comp_config.get("strategy", "average")
                out_of = float(comp_config.get("outOf", 10.0)) # Default out of 10
                
                if strategy == "bestN":
                    n = int(comp_config.get("n", 1))
                    sorted_vals = sorted(list_val, reverse=True)
                    best_n = sorted_vals[:n]
                    # Average of best N, then scaled to weight
                    avg_raw = sum(best_n) / len(best_n)
                    comp_obtained = (avg_raw / out_of) * weight
                
                elif strategy == "average":
                    avg_raw = sum(list_val) / len(list_val)
                    comp_obtained = (avg_raw / out_of) * weight
                
                elif strategy == "sum":
                    # Sum all, then scale. 
                    # Example: "taken for 10 convert to 5 and add all"
                    # If scaleFactor is 0.5 (5/10), then 8/10 becomes 4.
                    # If not provided, it scales such that sum of ALL expected quizzes = weight.
                    scale = float(comp_config.get("scaleFactor", 1.0))
                    
                    # If they didn't provide scaleFactor but provided outOf, 
                    # we can't easily guess total quizzes without more info.
                    # Fallback: if no scaleFactor, but weight and outOf exist:
                    if "scaleFactor" not in comp_config and out_of > 0:
                        total_n = int(comp_config.get("totalN", len(list_val)))
                        if total_n > 0:
                            scale = weight / (total_n * out_of)
                            
                    comp_obtained = sum(list_val) * scale
                
                else: # Default fallback to simple average
                    comp_obtained = (sum(list_val) / len(list_val)) if list_val else 0.0
        else:
            # Simple component (Mid, Final, etc.)
            comp_obtained = float(val) if val is not None else 0.0
            
        # Clamp obtained to max
        comp_obtained = min(comp_obtained, comp_max)
        
        total_obtained += comp_obtained
        total_max += comp_max
        
        component_breakdown.append({
            "name": component,
            "max": comp_max,
            "obtained": round(comp_obtained, 2)
        })

    percentage = (total_obtained / total_max * 100) if total_max > 0 else 0.0
    return total_obtained, total_max, percentage, component_breakdown

def predict_grade(percentage):
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

def update_semester_summary(db, user_id, semester_id):
    """
    Recalculates summary for the entire semester.
    """
    courses_ref = db.collection("users").document(user_id).collection("semesterProgress").document(semester_id).collection("courses")
    courses = courses_ref.stream()
    
    total_gp_credits = 0.0
    total_credits = 0.0
    summaries = []
    
    for doc in courses:
        data = doc.to_dict()
        credits = float(data.get("credits", 3.0))
        
        obtained, max_pts, pct, breakdown = calculate_course_score(data)
        grade, gpa = predict_grade(pct)
        
        total_gp_credits += (gpa * credits)
        total_credits += credits
        
        summaries.append({
            "courseCode": data.get("courseCode", doc.id),
            "credits": credits,
            "percentage": round(pct, 2),
            "grade": grade,
            "gpa": gpa,
            "obtained": round(obtained, 2),
            "max": round(max_pts, 2),
            "breakdown": breakdown
        })
        
    sgpa = (total_gp_credits / total_credits) if total_credits > 0 else 0.0
    
    # Save Summary
    db.collection("users").document(user_id).collection("semesterProgress").document(semester_id).set({
        "summary": {
            "sgpa": round(sgpa, 2),
            "totalCredits": total_credits,
            "lastUpdated": firestore.SERVER_TIMESTAMP,
            "courseSummaries": summaries
        }
    }, merge=True)
    
    return sgpa

def recalculate_academic_stats(db, user_id):
    """
    Recalculates CGPA, total credits, etc. by scanning courseHistory and enrolling sections.
    """
    user_ref = db.collection("users").document(user_id)
    # Fetch Course History from Subcollection (V2 Structure)
    profile_ref = user_ref.collection("academic_data").document("profile")
    profile_doc = profile_ref.get()
    
    course_history = {}
    if profile_doc.exists:
        profile_data = profile_doc.to_dict()
        course_history = profile_data.get('courseHistory', {})
    else:
        # Fallback to Root if still migrating (Optional, or fail safe)
        user_doc = user_ref.get()
        if user_doc.exists:
            course_history = user_doc.to_dict().get('courseHistory', {})

    total_points = 0.0
    total_credits = 0.0
    courses_completed = 0
    remained_credits = 140.0 # Default fallback
    
    # 1. Process History and Rebuild "semesters" List
    semesters_list = []
    
    if course_history and isinstance(course_history, dict):
        # Sort semesters chronologically if possible.
        # Fallback: Alphabetical might not be perfect (Fall2024 comes before Spring2025? No.)
        # Ideal: Parse year/semester. "Spring2025" -> (2025, 0), "Summer2025" -> (2025, 1), "Fall2025" -> (2025, 2)
        
        def sem_sorter(sem_str):
            match = re.search(r"(\D+)(\d{4})", sem_str)
            if not match: return (0, 0)
            ss, yy = match.group(1).lower(), int(match.group(2))
            order = 0
            if "spring" in ss: order = 1
            elif "summer" in ss: order = 2
            elif "fall" in ss: order = 3
            return (yy, order)

        sorted_keys = sorted(course_history.keys(), key=sem_sorter)
        
        cumulative_points_so_far = 0.0
        cumulative_credits_so_far = 0.0

        for semester in sorted_keys:
            courses_map = course_history[semester]
            if not isinstance(courses_map, dict): continue
            
            term_points = 0.0
            term_credits = 0.0
            term_courses_list = []
            
            for code, grade in courses_map.items():
                if grade is None: continue
                
                # Metadata credits lookup could go here if we had access to the master map
                # For now simplify to 3.0 or try to infer?
                # Using 3.0 as default, same as stats logic below
                credits = 3.0
                
                gp = 0.0
                status = "Ongoing"
                
                if grade in ["W", "I", ""]:
                    status = "Retake/Incomplete" if grade == "I" else "Withdrawn"
                elif grade == "Ongoing":
                    status = "Ongoing" 
                else:
                    status = "Completed"
                    gp = GRADE_POINTS.get(grade, 0.0)
                    if gp == 0.0 and grade != "F":
                        # Unknown grade logic?
                        pass
                    
                    term_points += (gp * credits)
                    term_credits += credits

                # Add to Global Stats (Only for completed)
                if status == "Completed" or grade == "F":
                     # Yes, F counts towards GPA usually but 0 points
                     total_points += (gp * credits)
                     total_credits += credits
                     if gp > 0:
                         courses_completed += 1

                term_courses_list.append({
                    "code": code,
                    "credits": credits,
                    "grade": grade,
                    "point": gp,
                    "status": status
                })
            
            # Term Stats
            term_gpa = (term_points / term_credits) if term_credits > 0 else 0.0
            
            # Cumulative Snapshot
            # Note: total_points tracks global, but for the "history list" 
            # we want the snapshot *at that time*.
            cumulative_points_so_far += term_points
            cumulative_credits_so_far += term_credits
            cum_gpa = (cumulative_points_so_far / cumulative_credits_so_far) if cumulative_credits_so_far > 0 else 0.0

            semesters_list.append({
                 "semesterName": semester,
                 "semesterId": semester.replace(" ", ""),
                 "termGPA": round(term_gpa, 2),
                 "cumulativeGPA": round(cum_gpa, 2),
                 "courses": term_courses_list
            })
    
    # Reverse list (Newest first) for UI? Or keep Oldest first?
    # Profile UI usually likes Newest first.
    semesters_list.sort(key=lambda x: sem_sorter(x["semesterName"]), reverse=True)

    # 2. Final Results
    cgpa = (total_points / total_credits) if total_credits > 0 else 0.0
    remained = max(0.0, remained_credits - total_credits)
    
    stats = {
        "cgpa": round(cgpa, 2),
        "totalCredits": round(total_credits, 1),
        "coursesCompleted": courses_completed,
        "remainedCredits": round(remained, 1),
        "lastUpdated": firestore.SERVER_TIMESTAMP,
        "semesters": semesters_list # <--- The crucial addition
    }
    
    # Update academic_data/profile subcollection
    user_ref.collection('academic_data').document('profile').set(stats, merge=True)
    
    # Also update root statistics for now (Dual Write) until frontend is fully verified?
    # No, user asked to clean root. But for safety, we removed 'statistics' field in migration.
    # So we should NOT write it back to root.
    
    return stats
