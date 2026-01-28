
import firebase_admin
from firebase_admin import storage
import os
import sys

# Ensure script can find modules if needed, though this is standalone
# sys.path.append(os.getcwd())

def upload_eml_to_trigger_function():
    try:
        firebase_admin.get_app()
    except ValueError:
        firebase_admin.initialize_app()

    bucket = storage.bucket()
    
    local_file = "Online Advising of Courses for Spring Semester 2026.eml"
    remote_path = "admin_uploads/advising_schedules/Spring2026.eml"
    
    if not os.path.exists(local_file):
        print(f"Error: {local_file} not found locally.")
        return

    print(f"Uploading {local_file} to {remote_path}...")
    blob = bucket.blob(remote_path)
    blob.upload_from_filename(local_file)
    
    print("Upload complete. This should trigger the 'on_advising_file_upload' Cloud Function.")
    print("Check Firebase Console Logs for execution details.")

if __name__ == "__main__":
    upload_eml_to_trigger_function()
