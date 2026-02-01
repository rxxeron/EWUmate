import firebase_admin
from firebase_admin import credentials, firestore
import json
import os
import datetime

# Path to your service account key
KEY_PATH = "config/serviceAccountKey.json"

def migrate_db_structure():
    print("🚀 Starting Database Redesign Migration...")
    
    if not os.path.exists(KEY_PATH):
        print(f"❌ Key missing at {KEY_PATH}")
        return

    # Initialize
    if not firebase_admin._apps:
        cred = credentials.Certificate(KEY_PATH)
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    users_ref = db.collection('users')
    
    # 1. Create Backup first
    print("\n📦 Creating Backup of Root Documents...")
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = f"users_backup_{timestamp}.json"
    
    all_users_data = {}
    users_stream = list(users_ref.stream())
    
    for user_doc in users_stream:
        all_users_data[user_doc.id] = user_doc.to_dict()
        
    with open(backup_file, 'w', encoding='utf-8') as f:
        json.dump(all_users_data, f, default=str)
    print(f"✅ Backup saved to {backup_file}")

    # 2. Perform Migration
    print("\n🧹 Cleaning up Root Documents...")
    count = 0
    
    # Fields to REMOVE from root 
    # (Because they are now handled in subcollections)
    fields_to_delete = {
        'weeklySchedule': firestore.DELETE_FIELD,
        # We keep 'courseHistory' and 'enrolledSections' briefly or move them? 
        # User request: "keep academic data remove users contains thing"
        # Assuming academic_data has everything needed.
        # Let's double check if we need to COPY safely first.
        'statistics': firestore.DELETE_FIELD,
        
        # NOTE: Be careful removing 'enrolledSections' if functions rely on it for updates.
        # For now, let's stick to the specific request: weeklySchedule & duplicate stats
        # The user said: "keep schedule and delete weekly schedule"
    }

    for user_doc in users_stream:
        uid = user_doc.id
        root_data = all_users_data[uid]
        
        # Verification: Does subcollection exist?
        sched_ref = users_ref.document(uid).collection('schedule').limit(1).get()
        acad_ref = users_ref.document(uid).collection('academic_data').document('profile').get()
        
        has_subcollections = len(sched_ref) > 0 and acad_ref.exists
        
        if has_subcollections:
            # Safe to delete root fields
            try:
                users_ref.document(uid).update(fields_to_delete)
                print(f"   Deleted redundant fields for {uid}")
                count += 1
            except Exception as e:
                print(f"   ❌ Error updating {uid}: {e}")
        else:
            print(f"   ⚠️ Skipping {uid}: Missing subcollections (not safe to delete root data)")

    print(f"\n🎉 Migration Complete. Cleaned up {count} users.")
    print(f"   Backup file: {backup_file}")

if __name__ == "__main__":
    migrate_db_structure()
