"""
Setup Firestore config documents for EWUmate app.
Run this script once to initialize required configuration.
"""
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase Admin (uses default credentials)
try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app()

db = firestore.client()

# 1. Set up config/app_info
app_info_ref = db.collection('config').document('app_info')
app_info_ref.set({
    'currentSemester': 'Spring2026',
    'latestVersion': '1.0.0',
    'downloadUrl': '',
    'minVersion': '1.0.0',
}, merge=True)
print("✅ Set config/app_info.currentSemester = 'Spring2026'")

# 2. Set up config/admin
admin_ref = db.collection('config').document('admin')
admin_ref.set({
    'secret_key': 'EWU_MATE_ADMIN_2026_SECURE',  # Change this to your preferred key
}, merge=True)
print("✅ Set config/admin.secret_key")

print("\n🎉 Config setup complete!")
print("\nYou can now run backfill_all_schedules from the admin panel or via HTTP call.")
