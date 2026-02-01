
import firebase_admin
from firebase_admin import firestore
import datetime

# Singleton cache for system status
_SYSTEM_STATUS_CACHE = {
    'last_updated': 0,
    'data': None
}
CACHE_TTL_SECONDS = 60 * 5  # Cache status for 5 minutes

def get_db():
    try:
        return firestore.client()
    except:
        return None

def check_system_status_and_limit(feature_name="global"):
    """
    Checks if the system is enabled and if limits are respected.
    Returns: (bool allowed, str reason)
    """
    db = get_db()
    if not db:
        return True, "No database connection"

    global _SYSTEM_STATUS_CACHE
    now = datetime.datetime.now().timestamp()

    # 1. Check Global System Flag (Cached)
    status_data = _SYSTEM_STATUS_CACHE['data']
    if not status_data or (now - _SYSTEM_STATUS_CACHE['last_updated'] > CACHE_TTL_SECONDS):
        try:
            doc = db.collection('config').document('system_status').get()
            if doc.exists:
                status_data = doc.to_dict()
                _SYSTEM_STATUS_CACHE['data'] = status_data
                _SYSTEM_STATUS_CACHE['last_updated'] = now
            else:
                # Default safety settings if config missing
                status_data = {"enabled": True} 
        except Exception as e:
            # On error, fail open generally, or closed if critical
            print(f"Error reading system status: {e}")
            status_data = {"enabled": True}

    if status_data:
        if not status_data.get('enabled', True):
            return False, f"System disabled: {status_data.get('reason', 'Admin disabled')}"
    
    # 2. Check Automated Global Limit (Cached periodically)
    # START DATE ENFORCEMENT: Only enforce after Feb 1, 2026
    enforcement_start = datetime.datetime(2026, 2, 1)
    if datetime.datetime.now() < enforcement_start:
         return True, "Enforcement starts Feb 1, 2026"

    global _GLOBAL_LIMIT_CACHE
    if now - _GLOBAL_LIMIT_CACHE['last_updated'] > 14400: # Check every 4 hours
         usage = get_total_global_usage()
         if usage > GLOBAL_DAILY_LIMIT:
             # Auto-disable system!
             disable_system("Daily limit exceeded (Auto)")
             return False, "Daily Global Limit Exceeded"
         _GLOBAL_LIMIT_CACHE['last_updated'] = now
    
    return True, "OK"

def disable_system(reason):
    db = get_db()
    if not db: return
    try:
        db.collection('config').document('system_status').set({
            'enabled': False,
            'reason': reason,
            'updatedAt': firestore.SERVER_TIMESTAMP
        }, merge=True)
        # Update local cache immediately
        _SYSTEM_STATUS_CACHE['data'] = {'enabled': False, 'reason': reason}
    except Exception as e:
        print(f"Failed to auto-disable system: {e}")

from sharded_counter import increment_global_counter, get_total_global_usage, GLOBAL_DAILY_LIMIT

_GLOBAL_LIMIT_CACHE = {
    'last_updated': 0
}

def check_rate_limit(user_id, action_type, limit=10, window_minutes=60):
    """
    Naive rate limiter using Firestore counters.
    Note: usage of this function incurs Firestore costs (Reads/Writes).
    Use sparingly (e.g. only on heavy actions).
    """
    # START DATE ENFORCEMENT: Only enforce after Feb 15, 2026 (grace period)
    enforcement_start = datetime.datetime(2026, 2, 15)
    if datetime.datetime.now() < enforcement_start:
         return True, "Rate limiting grace period active"

    try:
        db = get_db()
        # Shard by hour to avoid hotspotting
        now = datetime.datetime.utcnow()
        time_bucket = now.strftime('%Y%m%d_%H')
        
        doc_path = f"rate_limits/{action_type}_{time_bucket}_{user_id}"
        doc_ref = db.document(doc_path)
        
        # Transactional increment
        @firestore.transactional
        def increment_counter(transaction, ref):
            snapshot = transaction.get(ref)
            current_count = 0
            if snapshot.exists:
                current_count = snapshot.get('count')
            
            if current_count >= limit:
                return False
            
            if not snapshot.exists:
                transaction.set(ref, {'count': 1, 'expiresAt': now + datetime.timedelta(hours=2)})
            else:
                transaction.update(ref, {'count': firestore.Increment(1)})
            return True

        transaction = db.transaction()
        allowed = increment_counter(transaction, doc_ref)
        
        if not allowed:
            return False, f"Rate limit exceeded for {action_type}. Try again later."
        
        return True, "OK"
        
    except Exception as e:
        print(f"Rate limit check failed: {e}")
        # Fail open or closed? If DB fails, maybe fail closed for safety.
        return False, "Rate limit check error."

