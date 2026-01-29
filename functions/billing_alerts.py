
from firebase_functions import pubsub_fn
from firebase_admin import firestore
import json

@pubsub_fn.on_message_published(topic="billing-alerts")
def stop_billing_emergency(event: pubsub_fn.CloudEvent[pubsub_fn.MessagePublishedData]) -> None:
    """
    Listens to Pub/Sub topic 'billing-alerts'.
    If the budget notification says the threshold is crossed, it disables the system.
    """
    try:
        # Decode the Pub/Sub message
        import base64
        data_str = base64.b64decode(event.data.message.data).decode('utf-8')
        data = json.loads(data_str)
        
        # Budget notification format:
        # {
        #   "budgetDisplayName": "...",
        #   "alertThresholdExceeded": 1.0,
        #   "costAmount": 10.50,
        #   "costIntervalStart": "...",
        #   "currencyCode": "USD"
        # }

        cost = data.get('costAmount', 0)
        threshold = data.get('alertThresholdExceeded', 0)
        
        print(f"Budget Alert Received: Cost ${cost}, Threshold: {threshold}")

        # If we got this message, it usually means a threshold was crossed.
        # We can implement specific logic (e.g., only stop if > 90% or > $5)
        # For safety, we STOP if ANY alert is received on this topic.
        
        db = firestore.client()
        db.collection('config').document('system_status').set({
            'enabled': False,
            'reason': f"Budget Alert Triggered: Cost ${cost}",
            'updatedAt': firestore.SERVER_TIMESTAMP
        }, merge=True)
        
        print("🚨 SYSTEM EMERGENCY STOP TRIGGERED BY BILLING ALERT 🚨")

    except Exception as e:
        print(f"Error processing billing alert: {e}")
