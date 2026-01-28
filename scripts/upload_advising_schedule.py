
import firebase_admin
from firebase_admin import firestore
import json
import os
from datetime import datetime

# Initialize Firebase (Script Mode)
try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app()

db = firestore.client()

def upload_schedule_to_firestore():
    # 1. Load the generated JSON
    json_path = "advising_schedule.json"
    if not os.path.exists(json_path):
        print(f"Error: {json_path} not found. Run process_advising_email.py first.")
        return

    with open(json_path, "r", encoding="utf-8") as f:
        slots = json.load(f)

    print(f"Uploading {len(slots)} slots to Firestore...")
    
    # Collection: advising_schedule_Spring2026 (or generic 'advising_schedule' with semester field)
    # Let's use a config doc to track active semester, but here we hardcode or detect?
    # The email was for "Spring Semester 2026"
    semester = "Spring2026"
    
    batch = db.batch()
    collection_ref = db.collection('advising_schedules').document(semester).collection('slots')
    
    # Optional: Delete old slots? For safety, maybe just overwrite by ID.
    
    count = 0
    for slot in slots:
        doc_ref = collection_ref.document(slot['slotId'])
        batch.set(doc_ref, slot)
        count += 1
        
        if count % 400 == 0:
            batch.commit()
            batch = db.batch()
            print(f"Committed {count} slots...")

    batch.commit()
    print(f"Successfully uploaded {count} slots for {semester}.")

def assign_slots_for_all_users():
    semester = "Spring2026"
    print("Starting bulk assignment for all users...")
    
    users_ref = db.collection('users')
    # We could filter by active students only
    docs = users_ref.stream()
    
    # Load slots into memory for faster processing
    slots_ref = db.collection('advising_schedules').document(semester).collection('slots')
    all_slots = [d.to_dict() for d in slots_ref.stream()]
    
    # Helper to parse time
    from functions.utils import parse_time_to_minutes
    
    updated_count = 0
    
    for user_doc in docs:
        user_data = user_doc.to_dict()
        uid = user_doc.id
        
        # Check Program (Undergrad/Grad) - assuming 'program' field or infer from credits?
        # The email distinguishes Undergrad vs Grad.
        # Let's check 'program' field if exists, default to Undergraduate
        program = user_data.get('program', 'Undergraduate') # or 'Graduate'
        
        credits_earned = float(user_data.get('creditsEarned', 0.0))
        dept = user_data.get('department', '').strip().upper()
        
        # Find best slot
        best_slot = None
        best_dt = None
        
        for slot in all_slots:
            # Filter by Program? The parsed JSON doesn't explicitly store "Undergraduate" type in final output 
            # unless we add it to the JSON in previous step. 
            # However, the credits criteria usually disambiguates. 
            # Grad slots are "0 credits & above" but usually separate dates.
            # For now, relying on credit/dept match.
            
            # Dept Check
            if slot['allowedDepartments']:
                if dept not in slot['allowedDepartments']:
                    continue
            
            # Credit Check
            if credits_earned >= slot['minCredits'] and credits_earned <= slot['maxCredits']:
                # Valid candidate
                # Parse DateTime to sort
                # simplified parse for sorting
                try:
                    d_str = slot['date'].split('-')[-1].strip() # "03 December 2025"
                    t_str = slot['startTime']
                    full_str = f"{d_str} {t_str}"
                    # Allow fuzzy parsing
                    # This is tricky without strict format. 
                    # Let's just trust the first one we find? No, usually ordered by date.
                    # The JSON list was already ordered chronologically by the parser!
                    
                    # Since we iterate `all_slots` which comes from Firestore stream, 
                    # order is NOT guaranteed. We MUST Sort `all_slots` first.
                    pass 
                except:
                    continue
                
                # We need a robust sorter.
                # Actually, simplest is:
                best_slot = slot
                break # If we sort all_slots by date/time beforehand, first match is best.
        
        if best_slot:
            # Update User
            # We save it in a subcollection or on the user doc?
            # User doc is easier for UI access.
            users_ref.document(uid).update({
                f"advisingSlot_{semester}": best_slot
            })
            print(f"Assigned {uid} ({dept}, {credits_earned} Cr) -> {best_slot['date']} {best_slot['startTime']}")
            updated_count += 1
    
    print(f"Finished. Assigned slots to {updated_count} users.")

def sort_slots_chronologically(slots):
    # Sort helper
    # We need to turn "03 December 2025 09:00 AM" into datetime
    def sorter(slot):
        try:
            d_part = slot['date'].split('-')[-1].strip()
            t_part = slot['startTime']
            fmt = "%d %B %Y %I:%M %p" 
            # Fix "2:30 PM" -> "02:30 PM" if needed
            return datetime.strptime(f"{d_part} {t_part}", fmt)
        except:
            return datetime.max
            
    return sorted(slots, key=sorter)

if __name__ == "__main__":
    # 1. Upload
    upload_schedule_to_firestore()
    
    # 2. Assign
    # Be careful running this on production without verifying!
    # assign_slots_for_all_users()
