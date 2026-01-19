
import firebase_admin
from firebase_admin import credentials, firestore
import json

# Initialize
if not firebase_admin._apps:
    cred = credentials.Certificate("config/serviceAccountKey.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

def debug_users():
    print("Fetching users...")
    users = db.collection('users').limit(5).stream()
    
    count = 0
    for doc in users:
        count += 1
        uid = doc.id
        data = doc.to_dict()
        
        print(f"\n--- User: {uid} ---")
        print(f"Program ID: {data.get('programId')}")
        
        # Check Input
        history = data.get('courseHistory')
        if not history:
            print("❌ courseHistory is MISSING or EMPTY")
        else:
            print(f"✅ courseHistory found: {len(history)} semesters")
            print(json.dumps(history, indent=2))
            
        enrolled = data.get('enrolledSections')
        print(f"Enrolled: {enrolled}")
        
        # Check Output
        profile_doc = db.collection('users').document(uid).collection('academic_data').document('profile').get()
        if profile_doc.exists:
            p_data = profile_doc.to_dict()
            print("✅ Output Profile Found:")
            print(f"  - Program: {p_data.get('programName')}")
            print(f"  - CGPA: {p_data.get('cgpa')}")
            print(f"  - Credits: {p_data.get('totalCreditsEarned')}")
            print(f"  - Semesters: {len(p_data.get('semesters', []))}")
        else:
            print("❌ Output academic_data/profile is MISSING")

    if count == 0:
        print("No users found in database.")

if __name__ == "__main__":
    debug_users()
