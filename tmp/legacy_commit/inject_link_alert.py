import psycopg2
import datetime
import json

conn = psycopg2.connect('postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres')
cur = conn.cursor()
trigger_time = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(minutes=1)
user_id = "5470a0d0-327d-4286-a544-74396f24b1b0"

payload_json = json.dumps({"url": "https://www.ewu.edu.bd/"})

query = """
INSERT INTO notifications (user_id, trigger_at, title, body, type, is_dispatched, payload, alert_key) 
VALUES (%s, %s, %s, %s, %s, false, %s, %s)
ON CONFLICT (user_id, alert_key) DO UPDATE SET is_dispatched = false, trigger_at = EXCLUDED.trigger_at
"""

cur.execute(query, (
    user_id, 
    trigger_time.strftime('%Y-%m-%d %H:%M:%S+00'), 
    "Important Notice (With Link)", 
    "Please check out the new update. https://www.ewu.edu.bd", 
    "push_alert", 
    payload_json, 
    "link_test_2"
))

conn.commit()
print("Inserted link test notification.")