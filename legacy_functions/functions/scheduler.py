from firebase_functions import scheduler_fn, options
from firebase_admin import firestore, messaging
import datetime

@scheduler_fn.on_schedule(schedule="every 1 hours", timeout_sec=300, memory=options.MemoryOption.MB_512)
def check_reminders(event):
    """
    Hourly Cron Job to check for task reminders and send FCM notifications.
    Logic:
    - 24h before due date
    - 1h before due date
    - Daily 9 AM Prep for Exams (Mid-Term / Final)
    """
    db = firestore.client()
    users_ref = db.collection("users")
    
    # Iterate all users (Note: For large scale, use PubSub fan-out)
    users = users_ref.stream()
    
    now = datetime.datetime.now(datetime.timezone.utc)
    
    for user in users:
        user_id = user.id
        
        # 1. Get FCM Token
        token_doc = db.collection("users").document(user_id).collection("fcm_tokens").limit(1).get()
        fcm_tokens = [d.id for d in token_doc] # Ideally fetch valid tokens
        if not fcm_tokens:
            continue
        
        target_token = fcm_tokens[0] # Simplification: Send to first token
        
        # 2. Get Active Tasks
        tasks_ref = db.collection("users").document(user_id).collection("tasks")
        tasks = tasks_ref.where("isCompleted", "==", False).stream()
        
        for task in tasks:
            data = task.to_dict()
            title = data.get("title", "Task")
            course = data.get("courseCode", "")
            task_type = data.get("type", "assignment")
            
            due_str = data.get("dueDate", "")
            if not due_str: continue
            
            # Parse Date (ISO format usually)
            try:
                due_date = datetime.datetime.fromisoformat(due_str.replace("Z", "+00:00"))
                # If offset naive, assume UTC
                if due_date.tzinfo is None:
                    due_date = due_date.replace(tzinfo=datetime.timezone.utc)
            except:
                continue
                
            time_diff = due_date - now
            hours_diff = time_diff.total_seconds() / 3600
            
            notification_body = None
            notification_title = f"Reminder: {course}"

            # A. 24 Hour Reminder (23.5 to 24.5 hours)
            if 23.5 <= hours_diff <= 24.5:
                notification_body = f"{title} is due in 24 hours. Don't forget to submit!"
                # Custom Messages
                if task_type in ['quiz', 'shortQuiz', 'assignment', 'labReport']:
                     notification_body = "Prepare check for final review"
                elif task_type == 'presentation':
                     notification_body = "Check you dress and charm like prince"
                elif task_type == 'viva':
                     notification_body = "Get ready"
            
            # B. 1 Hour Reminder (0.5 to 1.5 hours)
            elif 0.5 <= hours_diff <= 1.5:
                 notification_body = f"{title} is due in 1 hour! Final check?"
                 # Same custom messages logic if desired, or simpler urgency
            
            # C. Daily 9 AM Exam Prep
            # Problem: Server is UTC. 9 AM Local? We don't know user timezone easily.
            # Workaround: Send at 9 AM UTC? Or just check if today is "Prep Day".
            # User requirement: "Daily 9 am". 
            # If we assume BD time (UTC+6), 9 AM = 3 AM UTC.
            # We can check if current hour is 3 AM UTC.
            if now.hour == 3 and task_type in ['midTerm', 'finalExam']:
                 # Check if due date is in future
                 if hours_diff > 24: # Don't conflict with 24h reminder
                     notification_title = "Critical Exam Prep"
                     notification_body = f"Time to study! {title} is approaching."

            
            # Send Notification
            if notification_body:
                send_fcm(target_token, notification_title, notification_body)

def send_fcm(token, title, body):
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            token=token,
        )
        response = messaging.send(message)
        # print('Successfully sent message:', response)
    except Exception as e:
        print(f"Error sending message: {e}")

@scheduler_fn.on_schedule(schedule="every 5 minutes", timeout_sec=60)
def process_scheduled_broadcasts(event):
    """
    Checks for pending scheduled broadcasts and sends them if time is due.
    """
    db = firestore.client()
    now = datetime.datetime.now(datetime.timezone.utc)
    
    # Query for 'scheduled' status
    # Note: Composite index might be needed for queries with inequality on separate fields if we added scheduledAt < now in query.
    # To be safe/simple, just fetch all 'scheduled' and filter in memory (assuming low volume).
    docs = db.collection("admin_broadcasts").where("status", "==", "scheduled").stream()
    
    for doc in docs:
        data = doc.to_dict()
        scheduled_at = data.get('scheduledAt')
        
        should_send = False
        
        if scheduled_at:
             # Convert to datetime
            dt_val = None
           # Helper to convert various timestamp formats
            if hasattr(scheduled_at, 'timestamp'):
                try:
                    dt_val = datetime.datetime.fromtimestamp(scheduled_at.timestamp(), datetime.timezone.utc)
                except: pass
            elif isinstance(scheduled_at, datetime.datetime):
                dt_val = scheduled_at
                if dt_val.tzinfo is None: dt_val = dt_val.replace(tzinfo=datetime.timezone.utc)
            
            if dt_val and dt_val <= now:
                should_send = True
        else:
            # No time set? Should have been sent immediately by trigger.
            # But if it got stuck in 'scheduled', send it now.
            should_send = True
            
        if should_send:
            title = data.get('title')
            body = data.get('body')
            link = data.get('link')
            
            if title and body:
                print(f"Sending Scheduled Broadcast: {title}")
                message = messaging.Message(
                    notification=messaging.Notification(title=title, body=body),
                    data={"click_action": "FLUTTER_NOTIFICATION_CLICK", "link": link if link else ""},
                    topic='all_users'
                )
                try:
                    response = messaging.send(message)
                    doc.reference.update({
                        'status': 'sent',
                        'sentAt': firestore.SERVER_TIMESTAMP,
                        'messageId': response
                    })
                except Exception as e:
                    print(f"Error sending scheduled broadcast: {e}")
                    doc.reference.update({'status': 'error', 'error': str(e)})
