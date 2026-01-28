
import sys
import os
import firebase_admin
from firebase_admin import firestore

# Ensure we can import from 'functions' directory
sys.path.append(os.getcwd())

from functions.assign_advising import assign_slot_to_user

def run_batch_assignment():
    # Initialize Firebase
    try:
        firebase_admin.get_app()
    except ValueError:
        firebase_admin.initialize_app()
        
    db = firestore.client()
    
    print("Fetching all users for advising slot assignment...")
    users_ref = db.collection('users')
    docs = users_ref.stream()
    
    count = 0
    assigned = 0
    errors = 0
    
    for doc in docs:
        count += 1
        user_id = doc.id
        
        # Call the shared logic
        result = assign_slot_to_user(db, user_id)
        
        if result.get("success"):
            slot = result["slot"]
            print(f"[OK] User {user_id}: Assigned {slot['date']} @ {slot['startTime']}")
            assigned += 1
        else:
            print(f"[SKIP] User {user_id}: {result.get('message')}")
            # errors += 1

    print(f"\nBatch Complete.")
    print(f"Total Users Scanned: {count}")
    print(f"Slots Assigned: {assigned}")

if __name__ == "__main__":
    run_batch_assignment()
