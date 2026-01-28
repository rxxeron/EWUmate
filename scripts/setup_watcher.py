
import firebase_admin
from firebase_admin import firestore

try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app()

db = firestore.client()

def setup_watcher():
    print("Initializing Watcher Configuration...")
    
    # 1. Create System Status Doc
    status_ref = db.collection('config').document('system_status')
    if not status_ref.get().exists:
        status_ref.set({
            'enabled': True,
            'reason': '',
            'updatedAt': firestore.SERVER_TIMESTAMP
        })
        print("✅ Created config/system_status with enabled=True")
    else:
        print("ℹ️ config/system_status already exists.")

    print("\nWatcher setup complete. Your functions are now guarded.")
    print("To disable functions in emergency, set 'enabled' to false in config/system_status.")

if __name__ == "__main__":
    setup_watcher()
