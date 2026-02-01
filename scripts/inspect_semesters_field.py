import firebase_admin
from firebase_admin import credentials, firestore
import json
import os

# Path to your service account key
KEY_PATH = "config/serviceAccountKey.json"

def inspect_semesters():
    if not os.path.exists(KEY_PATH):
        print("Key not found.")
        return

    if not firebase_admin._apps:
        cred = credentials.Certificate(KEY_PATH)
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    users_ref = db.collection('users')
    
    # Grab the first user with academic_data
    for user_doc in users_ref.limit(5).stream():
        profile_ref = user_doc.reference.collection('academic_data').document('profile')
        profile = profile_ref.get()
        
        if profile.exists:
            data = profile.to_dict()
            semesters = data.get('semesters')
            courseHistory = data.get('courseHistory')
            
            print(f"\nUser: {user_doc.id}")
            print(f"Has 'courseHistory' map? {courseHistory is not None}")
            if courseHistory:
                 print(f"Sample History Key: {list(courseHistory.keys())[0] if courseHistory else 'Empty'}")

            print(f"Has 'semesters' list? {semesters is not None}")
            if semesters and isinstance(semesters, list) and len(semesters) > 0:
                print("First Semester Object:")
                print(json.dumps(semesters[0], indent=2))
                return


if __name__ == "__main__":
    inspect_semesters()
