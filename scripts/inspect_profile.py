import firebase_admin
from firebase_admin import credentials, firestore
import json

# Initialize
cred = credentials.Certificate("service_account.json")
try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app(cred)

db = firestore.client()

def inspect_profile():
    # Find a user (using the one from previous context or generic query)
    # We'll just grab the first user with academic_data
    users = db.collection('users').limit(5).stream()
    
    for u in users:
        print(f"\nUser: {u.id}")
        u_data = u.to_dict()
        print(f"User Doc - ProgramID: {u_data.get('programId')}")
        print(f"User Doc - ProgramName: {u_data.get('programName')}")
        
        # Check Profile
        profile_ref = db.collection('users').document(u.id).collection('academic_data').document('profile')
        profile = profile_ref.get()
        
        if profile.exists:
            p_data = profile.to_dict()
            print("--- Academic Profile ---")
            print(f"Program Name: {p_data.get('programName')}")
            print(f"Total Credits: {p_data.get('totalCreditsEarned')}")
            print(f"Remained Credits: {p_data.get('remainedCredits')}")
            print(f"CGPA: {p_data.get('cgpa')}")
            
            # Check a few courses
            sems = p_data.get('semesters', [])
            print(f"Semesters Count: {len(sems)}")
            if sems:
                print(f"Latest Sem: {sems[0].get('semesterName')}")
                processed_courses = sems[0].get('courses', [])
                print(f"Courses in Latest Sem: {len(processed_courses)}")
                for c in processed_courses:
                    print(f" - {c.get('code')} ({c.get('credits')} cr)")
        else:
            print("No Academic Profile Doc found.")

if __name__ == "__main__":
    inspect_profile()
