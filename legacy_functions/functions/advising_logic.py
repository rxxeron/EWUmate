from firebase_admin import firestore
from firebase_functions import firestore_fn

@firestore_fn.on_document_written(document="advising_schedules/{scheduleId}")
def on_schedule_update(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]):
    """
    Triggered when an advising schedule is uploaded/updated.
    Iterates all users, finds their matching slot based on totalCredits,
    and updates their user document with the assigned slot.
    
    NOTE: Advising notifications are now handled by TypeScript Cloud Tasks
    (onAdvisingSlotUpdated in index.ts) when this function updates user slots.
    """
    snapshot = event.data.after
    if not snapshot: return
    
    schedule_data = snapshot.to_dict()
    if not schedule_data: return
    
    schedule_id = event.params['scheduleId']
    
    db = firestore.client()
    slots = schedule_data.get('slots', [])
    slots.sort(key=lambda x: x.get('minCredits', 0), reverse=True)
    
    print(f"Assigning slots for {schedule_id}. Total slots: {len(slots)}")
    
    users_ref = db.collection('users')
    docs = users_ref.stream()
    
    count = 0
    batch = db.batch()
    
    for doc in docs:
        user_data = doc.to_dict()
        stats = user_data.get('statistics', {})
        total_credits = stats.get('totalCredits', 0.0)
        
        assigned_slot = None
        for slot in slots:
            min_c = slot.get('minCredits', 0)
            max_c = slot.get('maxCredits', 9999)
            
            if min_c <= total_credits < max_c:
                assigned_slot = slot
                break
            if min_c <= total_credits and max_c >= 999.0:
                 assigned_slot = slot
                 break
        
        if assigned_slot:
            ref = users_ref.document(doc.id)
            slot_info = {
                'scheduleId': schedule_id,
                'startTime': assigned_slot['startTime'],
                'endTime': assigned_slot['endTime'],
                'displayTime': assigned_slot.get('displayTime', ''),
            }
            batch.update(ref, {'advisingSlot': slot_info})
            count += 1
            
            if count % 400 == 0:
                batch.commit()
                batch = db.batch()
                
    if count % 400 != 0:
        batch.commit()
    print(f"Assigned slots to {count} users.")
