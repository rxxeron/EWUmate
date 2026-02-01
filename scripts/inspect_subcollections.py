import firebase_admin
from firebase_admin import credentials, firestore
import json
import os

# Path to your service account key
KEY_PATH = "config/serviceAccountKey.json"

def inspect_subcollections():
    if not os.path.exists(KEY_PATH):
        print("Key not found.")
        return

    # Initialize
    if not firebase_admin._apps:
        cred = credentials.Certificate(KEY_PATH)
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    
    # Get a user with the schedule subcollection
    users = db.collection('users').limit(10).stream()
    
    for user in users:
        print(f"\nUser: {user.id}")
        
        # Check Schedule Subcollection
        schedule_ref = user.reference.collection('schedule')
        schedules = list(schedule_ref.stream())
        
        if schedules:
            print(f"✅ Found {len(schedules)} docs in 'schedule' subcollection.")
            for doc in schedules:
                print(f"   - Doc ID: {doc.id}")
                print(f"   - Fields: {list(doc.to_dict().keys())}")
        else:
            print("❌ No 'schedule' subcollection.")

        # Check Academic Data Subcollection
        acad_ref = user.reference.collection('academic_data')
        acad_docs = list(acad_ref.stream())
        if acad_docs:
             print(f"✅ Found {len(acad_docs)} docs in 'academic_data'.")
             for doc in acad_docs:
                 print(f"   - Doc ID: {doc.id}")
                 print(f"   - Fields: {list(doc.to_dict().keys())}")
        
        # Check Root Fields (to see what we are removing)
        root_data = user.to_dict()
        print(f"   - Root 'weeklySchedule' exists? {'weeklySchedule' in root_data}")


if __name__ == "__main__":
    inspect_subcollections()
