import firebase_admin
from firebase_admin import credentials, firestore
import os

KEY_PATH = "config/serviceAccountKey.json"

def migrate_history():
    print("📜 Moving courseHistory to academic_data/profile...")
    
    if not os.path.exists(KEY_PATH):
        print("Key not found.")
        return

    if not firebase_admin._apps:
        cred = credentials.Certificate(KEY_PATH)
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    users_ref = db.collection('users')
    
    count = 0
    
    # Stream all users
    for user_doc in users_ref.stream():
        uid = user_doc.id
        data = user_doc.to_dict()
        
        # Check if root has history
        history = data.get('courseHistory')
        completed = data.get('completedCourses')
        
        if history or completed:
            # Move to Subcollection
            updates = {}
            if history: updates['courseHistory'] = history
            if completed: updates['completedCourses'] = completed
            
            if updates:
                try:
                    # 1. Write to Subcollection
                    users_ref.document(uid).collection('academic_data').document('profile').set(updates, merge=True)
                    
                    # 2. Delete from Root
                    users_ref.document(uid).update({
                        'courseHistory': firestore.DELETE_FIELD,
                        'completedCourses': firestore.DELETE_FIELD
                    })
                    print(f"✅ Moved history for {uid}")
                    count += 1
                except Exception as e:
                    print(f"❌ Error {uid}: {e}")
    
    print(f"\nMigration Complete. Updated {count} users.")

if __name__ == "__main__":
    migrate_history()
