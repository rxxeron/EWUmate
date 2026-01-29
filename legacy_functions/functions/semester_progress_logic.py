"""
Cloud Function: Semester Progress Calculations
Trigger: Firestore Document Write on marks data
Output: Summary document with calculated stats
"""
from firebase_functions import firestore_fn, options
from firebase_admin import firestore
import re


@firestore_fn.on_document_written(
    document="users/{userId}/semesterProgress/{semesterId}/courses/{courseId}",
    region="us-central1",
    memory=options.MemoryOption.MB_256
)
def calculate_semester_progress(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Triggers when a course's marks data changes.
    Recalculates the entire semester's summary.
    """
    user_id = event.params["userId"]
    semester_id = event.params["semesterId"]
    
    db = firestore.client()
    
    # Fetch all courses for this semester
    courses_ref = db.collection("users").document(user_id).collection("semesterProgress").document(semester_id).collection("courses")
    courses = courses_ref.stream()
    
    total_weighted_obtained = 0.0
    total_weighted_max = 0.0
    course_summaries = []
    
    for course_doc in courses:
        course_data = course_doc.to_dict()
        if not course_data:
            continue
            
        course_code = course_data.get("courseCode", course_doc.id)
        credits = float(course_data.get("credits", 3.0))
        
        # Get marks distribution and obtained marks
        distribution = course_data.get("distribution", {})
        obtained = course_data.get("obtained", {})
        
        course_obtained = 0.0
        course_max = 0.0
        component_results = []
        
        for component, weight in distribution.items():
            weight_val = float(weight) if weight else 0.0
            obtained_val = obtained.get(component, 0.0)
            
            # Handle quiz arrays (multiple quizzes)
            if isinstance(obtained_val, list):
                if len(obtained_val) > 0:
                    avg_obtained = sum(obtained_val) / len(obtained_val)
                else:
                    avg_obtained = 0.0
                obtained_val = avg_obtained
            else:
                obtained_val = float(obtained_val) if obtained_val else 0.0
            
            # Normalize to percentage (assuming max is weight itself for now)
            # In a real scenario, we'd need max marks per component
            course_obtained += obtained_val
            course_max += weight_val
            
            component_results.append({
                "component": component,
                "weight": weight_val,
                "obtained": obtained_val
            })
        
        # Calculate percentage for this course
        if course_max > 0:
            course_percentage = (course_obtained / course_max) * 100
        else:
            course_percentage = 0.0
        
        # Predict grade based on percentage
        predicted_grade = _predict_grade(course_percentage)
        predicted_gpa = _grade_to_gpa(predicted_grade)
        
        total_weighted_obtained += predicted_gpa * credits
        total_weighted_max += credits
        
        course_summaries.append({
            "courseCode": course_code,
            "credits": credits,
            "currentPercentage": round(course_percentage, 2),
            "predictedGrade": predicted_grade,
            "predictedGPA": predicted_gpa,
            "components": component_results
        })
    
    # Calculate overall semester GPA prediction
    if total_weighted_max > 0:
        predicted_sgpa = total_weighted_obtained / total_weighted_max
    else:
        predicted_sgpa = 0.0
    
    # Write summary
    summary_ref = db.collection("users").document(user_id).collection("semesterProgress").document(semester_id)
    summary_ref.set({
        "summary": {
            "predictedSGPA": round(predicted_sgpa, 2),
            "totalCredits": total_weighted_max,
            "courseSummaries": course_summaries,
            "lastUpdated": firestore.SERVER_TIMESTAMP
        }
    }, merge=True)
    
    print(f"Updated semester progress for {user_id}/{semester_id}: SGPA={predicted_sgpa:.2f}")


def _predict_grade(percentage: float) -> str:
    """Predict letter grade based on percentage."""
    if percentage >= 90: return "A+"
    if percentage >= 85: return "A"
    if percentage >= 80: return "A-"
    if percentage >= 75: return "B+"
    if percentage >= 70: return "B"
    if percentage >= 65: return "B-"
    if percentage >= 60: return "C+"
    if percentage >= 55: return "C"
    if percentage >= 50: return "D"
    return "F"


def _grade_to_gpa(grade: str) -> float:
    """Convert letter grade to GPA (New Scale)."""
    grades = {
        "A+": 4.00, "A": 3.75, "A-": 3.50, "B+": 3.25,
        "B": 3.00, "B-": 2.75, "C+": 2.50, "C": 2.25,
        "D": 2.00, "F": 0.00
    }
    return grades.get(grade, 0.0)
