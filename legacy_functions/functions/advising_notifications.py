from firebase_functions import scheduler_fn, options
from firebase_admin import firestore, messaging
import datetime

@scheduler_fn.on_schedule(schedule="every 5 minutes", timeout_sec=120, memory=options.MemoryOption.MB_512)
def check_advising_windows(event):
    """
    Checks if active advising slots are approaching (24h, 1h, 30m, 5m).
    Sends FCM notifications to students who fall within that credit range.
    """
    db = firestore.client()
    now = datetime.datetime.now(datetime.timezone.utc)
    
    # 1. Get Latest Advising Schedule
    schedules = db.collection('advising_schedules').stream()
    
    for schedule in schedules:
        data = schedule.to_dict()
        slots = data.get('slots', [])
        
        for slot in slots:
            # Parse start time
            start_time = slot.get('startTime')
            if not start_time: continue
            
            # Ensure DateTime
            dt_start = None
            if hasattr(start_time, 'timestamp'):
                dt_start = datetime.datetime.fromtimestamp(start_time.timestamp(), datetime.timezone.utc)
            elif isinstance(start_time, datetime.datetime):
                dt_start = start_time
                if dt_start.tzinfo is None: dt_start = dt_start.replace(tzinfo=datetime.timezone.utc)
                
            if not dt_start: continue
            
            # Time Difference in Minutes
            diff = dt_start - now
            minutes_diff = diff.total_seconds() / 60
            
            # Targets: 24h(1440), 1h(60), 30m, 5m
            # Tolerance: +/- 2.5 minutes (half of cron interval) to ensure we hit it once
            targets = [1440, 60, 30, 5]
            
            matched_target = None
            for t in targets:
                if (t - 2.5) <= minutes_diff < (t + 2.5):
                    matched_target = t
                    break
            
            if matched_target:
                # Target Audience
                min_c = slot.get('minCredits', 0)
                max_c = slot.get('maxCredits', 999)
                
                print(f"Advising Alert ({matched_target}m): Credits {min_c}-{max_c} at {dt_start}")
                
                 # Batch Send
                _notify_students_in_range(db, min_c, max_c, dt_start, matched_target)

def _notify_students_in_range(db, min_c, max_c, start_time, minutes_left):
    # Query Users by Credits
    try:
        users = db.collection('users')\
            .where('statistics.totalCredits', '>=', min_c)\
            .where('statistics.totalCredits', '<', max_c)\
            .stream()
            
        target_tokens = []
        for user in users:
             token_docs = user.reference.collection('fcm_tokens').limit(1).stream()
             for t in token_docs:
                 target_tokens.append(t.id)
        
        if not target_tokens: return
        
        # Message Logic
        time_str = start_time.strftime("%I:%M %p")
        title = "Advising Alert! ⏰"
        body = ""
        
        if minutes_left >= 1430: # ~24h
            title = "Advising Starts Tomorrow! 📅"
            body = f"Your window ({min_c}-{max_c} Credits) opens tomorrow at {time_str}."
        elif minutes_left >= 55: # ~1h
            body = f"Get ready! Your advising window opens in 1 hour at {time_str}."
        elif minutes_left >= 25: # ~30m
            body = f"Only 30 minutes left! Advising starts at {time_str}."
        elif minutes_left <= 10: # ~5m
            title = "Advising Starts Now! 🚀"
            body = f"Your window opens in 5 minutes! Open the app now."
        
        message = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            tokens=target_tokens[:500]
        )
        response = messaging.send_multicast(message)
        print(f"Sent {response.success_count} notifications for {minutes_left}m alert.")
        
    except Exception as e:
        print(f"Error querying/sending for credits {min_c}-{max_c}: {e}")
