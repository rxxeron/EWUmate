import psycopg2
import datetime
conn = psycopg2.connect('postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres')
cur = conn.cursor()
trigger_time = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(minutes=1)
user_id = "5470a0d0-327d-4286-a544-74396f24b1b0"
cur.execute(f"INSERT INTO notifications (user_id, trigger_at, title, body, type, is_dispatched, payload, alert_key) VALUES ('{user_id}', '{trigger_time.strftime('%Y-%m-%d %H:%M:%S+00')}', 'Manual Connection Test', 'Your push notification system is online!', 'push_alert', false, '{{}}', 'manual_test_1') ON CONFLICT DO NOTHING")
conn.commit()
print("Inserted test notification.")