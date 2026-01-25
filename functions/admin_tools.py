from firebase_functions import https_fn, options
from firebase_admin import storage, firestore
import base64

# One-time bootstrap key - change this after first use!
BOOTSTRAP_KEY = "FIRST_TIME_SETUP_2026"

def _get_admin_secret():
    """Fetch admin secret from Firestore config/admin document."""
    db = firestore.client()
    doc = db.collection('config').document('admin').get()
    if doc.exists:
        return doc.to_dict().get('secret_key', '')
    return ''


@https_fn.on_call()
def bootstrap_config(req: https_fn.CallableRequest) -> any:
    """
    One-time setup function to initialize config documents.
    Uses a bootstrap key instead of admin secret (since it doesn't exist yet).
    IMPORTANT: Change BOOTSTRAP_KEY after first use!
    """
    data = req.data
    bootstrap_secret = data.get('bootstrap_key')
    new_admin_key = data.get('admin_key', 'EWU_MATE_ADMIN_2026_SECURE')
    current_semester = data.get('semester', 'Spring2026')
    
    if bootstrap_secret != BOOTSTRAP_KEY:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNAUTHENTICATED, 
                                   message="Invalid bootstrap key")
    
    db = firestore.client()
    
    # Set up config/admin
    db.collection('config').document('admin').set({
        'secret_key': new_admin_key
    }, merge=True)
    
    # Set up config/app_info
    db.collection('config').document('app_info').set({
        'currentSemester': current_semester,
        'latestVersion': '1.0.0',
        'minVersion': '1.0.0',
    }, merge=True)
    
    return {
        "success": True,
        "message": f"Config initialized. Admin key set. Semester: {current_semester}",
        "warning": "IMPORTANT: Change BOOTSTRAP_KEY in admin_tools.py and redeploy!"
    }


@https_fn.on_call(memory=options.MemoryOption.GB_1)
def upload_file_via_admin(req: https_fn.CallableRequest) -> any:
    """
    Uploads a file to Firebase Storage via Admin SDK.
    Admin key is stored in Firestore config/admin.secret_key
    """
    data = req.data
    secret = data.get('secret')
    
    # Security Check - fetch from Firestore
    expected_secret = _get_admin_secret()
    if not expected_secret or secret != expected_secret:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNAUTHENTICATED, message="Invalid Secret")

    filename = data.get('filename')
    folder = data.get('folder')
    file_b64 = data.get('file_base64') # Data URL or raw base64? Assume raw base64 content
    
    if not filename or not folder or not file_b64:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT, message="Missing fields")

    # Allowed Folders (Security)
    ALLOWED_FOLDERS = ["facultylist", "academiccalendar", "examschedule", "advisingschedule"]
    if folder not in ALLOWED_FOLDERS:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT, message=f"Invalid folder. Allowed: {ALLOWED_FOLDERS}")

    try:
        # Decode Base64
        # Handle Data URL scheme if present (e.g. "data:application/pdf;base64,.....")
        if ',' in file_b64:
            file_b64 = file_b64.split(',')[1]
            
        file_bytes = base64.b64decode(file_b64)
        
        # Upload
        bucket = storage.bucket()
        blob = bucket.blob(f"{folder}/{filename}")
        blob.upload_from_string(file_bytes, content_type="application/pdf") # Assuming PDF mostly, or auto-detect
        
        return {"success": True, "path": f"{folder}/{filename}"}
        
    except Exception as e:
        print(f"Upload Error: {e}")
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INTERNAL, message=str(e))


@https_fn.on_call(memory=options.MemoryOption.GB_1, timeout_sec=300)
def backfill_all_schedules(req: https_fn.CallableRequest) -> any:
    """
    Admin tool to regenerate schedules for ALL users.
    Useful if parsing logic changes or to fix issues.
    """
    secret = req.data.get('secret')
    expected_secret = _get_admin_secret()
    if not expected_secret or secret != expected_secret:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNAUTHENTICATED, message="Invalid Secret")

    db = firestore.client()
    
    # Determine current semester from config
    try:
        config_doc = db.collection('config').document('app_info').get()
        if config_doc.exists:
            semester_id = config_doc.to_dict().get('currentSemester', '')
        else:
            semester_id = ''
    except:
        semester_id = ''
    
    if not semester_id:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION, message="No current semester configured.")

    # Normalize semester ID (e.g., "Spring 2026" -> "Spring2026")
    semester_id = semester_id.replace(' ', '')
    
    users_ref = db.collection('users')
    
    from schedule_logic import _generate_schedule_for_user
    
    count = 0
    errors = 0
    
    try:
        docs = users_ref.stream()
        for doc in docs:
            try:
                data = doc.to_dict()
                sections = data.get('enrolledSections', [])
                if sections:
                    print(f"Backfilling schedule for {doc.id} for semester {semester_id}...")
                    _generate_schedule_for_user(db, doc.id, semester_id, set(sections))
                    count += 1
            except Exception as e:
                print(f"Error backfilling {doc.id}: {e}")
                errors += 1
                
        return {"success": True, "processed": count, "errors": errors}
        
    except Exception as e:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INTERNAL, message=str(e))

@https_fn.on_call(memory=options.MemoryOption.GB_1, timeout_sec=300)
def recalculate_all_stats(req: https_fn.CallableRequest) -> any:
    """
    Force recalulate academic stats (CGPA, Enrolled, Program) for all users.
    Triggers by updating 'lastTouch' timestamp on user docs.
    """
    print("recalculate_all_stats called")
    secret = req.data.get('secret')
    expected_secret = _get_admin_secret()
    if not expected_secret or secret != expected_secret:
        print("Invalid secret provided")
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNAUTHENTICATED, message="Invalid Secret")

    db = firestore.client()
    users_ref = db.collection('users')
    
    count = 0
    try:
        # Just update 'lastTouch' field which triggers calculate_academic_stats
        docs = users_ref.stream()
        batch = db.batch()
        batch_size = 0
        
        for doc in docs:
            ref = users_ref.document(doc.id)
            batch.set(ref, {"lastTouch": firestore.SERVER_TIMESTAMP}, merge=True)
            batch_size += 1
            count += 1
            
            if batch_size >= 400:
                batch.commit()
                batch = db.batch()
                batch_size = 0
                print(f"Committed batch of 400 updates...")
        
        if batch_size > 0:
            batch.commit()
            print(f"Committed final batch.")
            
        return {"success": True, "triggered_count": count}
        
    except Exception as e:
        print(f"Error in recalculate_all_stats: {e}")
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INTERNAL, message=str(e))

@https_fn.on_call(memory=options.MemoryOption.GB_1)
def debug_user_data(req: https_fn.CallableRequest) -> any:
    """
    Debug tool: Dumps the first user's data and profile.
    """
    secret = req.data.get('secret')
    expected_secret = _get_admin_secret()
    if not expected_secret or secret != expected_secret:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNAUTHENTICATED, message="Invalid Secret")

    db = firestore.client()
    users = db.collection('users').limit(1).stream()
    
    result = {}
    
    for doc in users:
        uid = doc.id
        data = doc.to_dict()
        
        # Output Profile
        profile_doc = db.collection('users').document(uid).collection('academic_data').document('profile').get()
        p_data = profile_doc.to_dict() if profile_doc.exists else "MISSING"
        
        result[uid] = {
            "input_courseHistory": data.get('courseHistory'),
            "input_programId": data.get('programId'),
            "output_profile": p_data
        }
        
    return result
