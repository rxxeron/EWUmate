import firebase_admin
from firebase_admin import credentials, firestore
import json

# Initialize Admin SDK (if not already)
try:
    firebase_admin.get_app()
except ValueError:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()
users_ref = db.collection('users')

print("Fetching users...")
docs = users_ref.stream()

for doc in docs:
    data = doc.to_dict()
    print(f"\nUser ID: {doc.id}")
    print(f"Program ID: {data.get('programId')}")
    print(f"Enrolled Sections: {data.get('enrolledSections')}")
    
    # Print Course History (summary)
    history = data.get('courseHistory', {})
    print(f"Course History Keys: {list(history.keys())}")
    for sem, courses in history.items():
        print(f"  {sem}: {courses}")
        
    # Print calculated stats
    print(f"Calculated Statistics: {data.get('statistics')}")
    
    # Check Profile subcollection
    profile_ref = doc.reference.collection('academic_data').document('profile').get()
    if profile_ref.exists:
        p_data = profile_ref.to_dict()
        print(f"Profile Document Program: {p_data.get('programName')}")
        print(f"Profile Semesters Count: {len(p_data.get('semesters', []))}")
        if p_data.get('semesters'):
            print(f"First Semester: {p_data['semesters'][0]}")
    else:
        print("Profile Document: MISSING")
