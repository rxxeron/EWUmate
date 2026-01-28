from firebase_functions import https_fn, options
from firebase_admin import messaging, firestore

def _get_admin_secret():
    """Fetch admin secret from Firestore config/admin document."""
    db = firestore.client()
    doc = db.collection('config').document('admin').get()
    if doc.exists:
        return doc.to_dict().get('secret_key', '')
    return ''

@https_fn.on_call()
def send_broadcast_notification(req: https_fn.CallableRequest) -> any:
    """
    Sends a broadcast notification to all users subscribed to 'all_users' topic.
    Admin key is stored in Firestore config/admin.secret_key
    """
    data = req.data
    secret = data.get('secret')
    
    # Verify Secret from Firestore (not hardcoded)
    expected_secret = _get_admin_secret()
    if not expected_secret or secret != expected_secret:
        # Fallback to standard Auth if secret missing (for future admin app)
        if not req.auth:
             raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNAUTHENTICATED, message="Invalid Secret or Auth")

    title = data.get('title')
    body = data.get('body')
    link = data.get('link')

    if not title or not body:
         raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT, message="Title and Body are required")

    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data={
                "click_action": "FLUTTER_NOTIFICATION_CLICK",
                "link": link if link else ""
            },
            topic='all_users'
        )
        
        response = messaging.send(message)
        return {"success": True, "messageId": response}
    except Exception as e:
        print(f"Error sending broadcast: {e}")
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INTERNAL, message=str(e))
