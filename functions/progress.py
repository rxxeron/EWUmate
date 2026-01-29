
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
    user_doc = user_ref.get()
    if not user_doc.exists:
        return
    
    data = user_doc.to_dict()
    course_history = data.get('courseHistory', {})
    
    total_points = 0.0
    total_credits = 0.0
    courses_completed = 0
    remained_credits = 140.0 # Default fallback
    
    # 1. Process History
    if course_history and isinstance(course_history, dict):
        for semester in course_history:
            courses = course_history[semester]
            if not isinstance(courses, dict): continue
            
            for code, grade in courses.items():
                if grade in ["Ongoing", "W", "I", ""]: continue
                
                # Assume 3.0 credits for now, or fetch from metadata if needed. 
                # Keeping it simple as per legacy logic
                credits = 3.0
                gp = GRADE_POINTS.get(grade, 0.0)
                
                total_points += (gp * credits)
                total_credits += credits
                if gp > 0:
                    courses_completed += 1

    # 2. Final Results
    cgpa = (total_points / total_credits) if total_credits > 0 else 0.0
    remained = max(0.0, remained_credits - total_credits)
    
    stats = {
        "cgpa": round(cgpa, 2),
        "totalCredits": round(total_credits, 1),
        "coursesCompleted": courses_completed,
        "remainedCredits": round(remained, 1),
        "lastUpdated": firestore.SERVER_TIMESTAMP
    }
    
    user_ref.update({"statistics": stats})
    return stats
