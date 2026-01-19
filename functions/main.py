import os
import re
from firebase_functions import storage_fn, https_fn
from firebase_admin import initialize_app, firestore, storage as admin_storage

# Initialize App FIRST (Before importing modules that use it)
try:
    initialize_app()
except ValueError:
    pass # Already initialized

import parser_course
import parser_calendar
import parser_exam
import parser_advising
from scheduler import check_reminders, process_scheduled_broadcasts 
from advising_logic import on_schedule_update  # check_advising_alerts moved to TypeScript
from academic_logic import calculate_academic_stats 
from semester_progress_logic import calculate_semester_progress
from schedule_logic import generate_user_schedule, on_enrollment_change
from notifications import send_broadcast_notification
from triggers import on_app_info_updated
from admin_tools import upload_file_via_admin, backfill_all_schedules, bootstrap_config, recalculate_all_stats, fix_metadata_credits
from advising_notifications import check_advising_windows

import firebase_functions.options as options

@storage_fn.on_object_finalized(memory=options.MemoryOption.GB_1, timeout_sec=300)
def process_uploaded_file(event: storage_fn.CloudEvent[storage_fn.StorageObjectData]):
    """
    Triggers when a file is uploaded to Storage.
    Routes to specific parsers based on folder path.
    """
    file_path = event.data.name
    bucket_name = event.data.bucket
    
    _process_file_internal(file_path, bucket_name)

@https_fn.on_request(memory=options.MemoryOption.GB_1, timeout_sec=540)
def refresh_storage_files(req: https_fn.Request) -> https_fn.Response:
    """
    HTTP Trigger to manually re-process all files in watched folders.
    Useful for applying new parser logic to existing files.
    """
    bucket = admin_storage.bucket() # Default bucket
    bucket_name = bucket.name
    
    watched_folders = [
        "facultylist/",
        "academiccalendar/",
        "examschedule/",
        "advisingschedule/"
    ]
    
    processed_count = 0
    errors = []
    
    for folder in watched_folders:
        blobs = bucket.list_blobs(prefix=folder)
        for blob in blobs:
            if blob.name.endswith("/"): continue # Skip folder itself
            
            try:
                print(f"Refinement: Reprocessing {blob.name}...")
                _process_file_internal(blob.name, bucket_name)
                processed_count += 1
            except Exception as e:
                print(f"Error reprocessing {blob.name}: {e}")
                errors.append(f"{blob.name}: {str(e)}")
                
    return https_fn.Response(f"Processed {processed_count} files. Errors: {len(errors)}")

def _process_file_internal(file_path: str, bucket_name: str):
    """
    Core logic to determine file type, download, parse, and write to Firestore.
    """
    db = firestore.client()
    path_lower = file_path.lower()
    
    # Supported Types
    is_pdf = path_lower.endswith('.pdf')
    is_eml = path_lower.endswith('.eml')
    
    if not (is_pdf or is_eml):
        print(f"Skipping unsupported file: {file_path}")
        return

    # Determine Type based on Folder
    doc_type = None
    collection_prefix = ""
    
    if path_lower.startswith("facultylist/"):
        doc_type = "COURSE"
        collection_prefix = "courses_"
    elif path_lower.startswith("academiccalendar/"):
        doc_type = "CALENDAR"
        collection_prefix = "calendar_"
    elif path_lower.startswith("examschedule/"):
        doc_type = "EXAM"
        collection_prefix = "exams_"
    elif path_lower.startswith("advisingschedule/") and is_eml:
        doc_type = "ADVISING"
        collection_prefix = "advising_schedules" # Not prefix, direct collection
    else:
        print(f"File {file_path} is not in a watched folder. Skipping.")
        return

    # Extract Semester ID
    filename = os.path.basename(file_path)
    semester_id = "Unknown"
    
    match = re.search(r"(Spring|Summer|Fall)[-_\s]?(\d{4})", filename, re.IGNORECASE)
    if match:
        semester_id = f"{match.group(1).capitalize()} {match.group(2)}"
    else:
        print(f"Could not extract semester from filename: {filename}. Defaulting to 'Unknown'.")
    
    print(f"Processing {filename} as {doc_type} for {semester_id}...")

    # Download file to temp
    bucket = admin_storage.bucket(bucket_name)
    blob = bucket.blob(file_path)
    temp_local_path = f"/tmp/{filename}"
    
    # Ensure tmp directory exists
    os.makedirs(os.path.dirname(temp_local_path), exist_ok=True)
    
    try:
        blob.download_to_filename(temp_local_path)
        
        extracted_data = []
        
        # Helper for metadata logic (Course only)
        course_titles = {}
        if doc_type == "COURSE":
            try:
                meta_doc = db.collection("metadata").document("courses").get()
                if meta_doc.exists:
                    data = meta_doc.to_dict()
                    if "list" in data and isinstance(data["list"], list):
                        for item in data["list"]:
                            if isinstance(item, dict):
                                code = str(item.get("code", "")).replace(" ", "").upper()
                                if code: course_titles[code] = item
                    else:
                        course_titles = data
            except Exception as e:
                print(f"Error fetching course metadata: {e}")

        if doc_type == "COURSE":
            extracted_data = parser_course.parse_course_pdf(temp_local_path, semester_id, course_titles)
        elif doc_type == "CALENDAR":
            extracted_data = parser_calendar.parse_calendar_pdf(temp_local_path, semester_id)
        elif doc_type == "EXAM":
            extracted_data = parser_exam.parse_exam_pdf(temp_local_path, semester_id)
        elif doc_type == "ADVISING":
            extracted_data = parser_advising.parse_advising_eml(temp_local_path, semester_id)
            
        print(f"Extracted {len(extracted_data)} items.")
        
        if extracted_data:
            if doc_type == "ADVISING":
                # Advising follows different collection pattern (generic collection, not per-semester collection)
                write_to_firestore(extracted_data, "advising_schedules")
            else:
                collection_name = f"{collection_prefix}{semester_id.replace(' ', '')}"
                write_to_firestore(extracted_data, collection_name)
            
    except Exception as e:
        print(f"Error processing File: {e}")
        # We don't raise here for batch processing so one failure doesn't stop others
        # but we print it clearly.
        
    finally:
        if os.path.exists(temp_local_path):
            try:
                os.remove(temp_local_path)
            except Exception:
                pass

def write_to_firestore(data_list, collection_name):
    """
    Writes a list of dicts to Firestore in batches.
    """
    # Ensure db is available
    if 'db' not in globals():
        db = firestore.client()
        
    batch = db.batch()
    count = 0
    total = 0
    
    print(f"Writing to collection: {collection_name}")
    
    for item in data_list:
        # Use 'docId' if present, otherwise auto-id
        if "docId" in item and item["docId"]:
            doc_ref = db.collection(collection_name).document(item["docId"])
        else:
            doc_ref = db.collection(collection_name).document()
            
        batch.set(doc_ref, item)
        count += 1
        
        if count >= 400:
            batch.commit()
            batch = db.batch()
            total += count
            count = 0
            print(f"Committed {total} records...")
            
    if count > 0:
        batch.commit()
        total += count
        
    print(f"Finished writing {total} records to {collection_name}.")
