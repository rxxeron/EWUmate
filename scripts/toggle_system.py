
import firebase_admin
from firebase_admin import firestore

try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app()

db = firestore.client()

def set_system_status(enabled: bool):
    status = "ENABLED" if enabled else "DISABLED"
    print(f"Setting system status to {status}...")
    
    db.collection('config').document('system_status').set({
        'enabled': enabled,
        'updatedAt': firestore.SERVER_TIMESTAMP,
        'reason': 'Manual toggle via script'
    }, merge=True)
    
    print(f"✅ System is now {status}.")

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        arg = sys.argv[1].lower()
        if arg == "on":
            set_system_status(True)
        elif arg == "off":
            set_system_status(False)
        else:
            print("Usage: python toggle_system.py [on|off]")
    else:
        print("Usage: python toggle_system.py [on|off]")
