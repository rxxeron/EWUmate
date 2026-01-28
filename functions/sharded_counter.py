
import firebase_admin
from firebase_admin import firestore
import random
import datetime

# --- CONFIGURATION ---
NUM_SHARDS = 10  # Good for up to ~10-50 updates/second
SAMPLING_RATE = 0.1 # Only record 10% of requests (multiplies count by 10)
GLOBAL_DAILY_LIMIT = 5000 # Means ~50,000 actual requests allowed per day

def get_db():
    try:
        return firestore.client()
    except ValueError:
        return None

def get_daily_shard_collection():
    db = get_db()
    if not db: return None
    today = datetime.datetime.utcnow().strftime('%Y-%m-%d')
    return db.collection('stats').document('global_usage').collection(today)

def increment_global_counter():
    """
    Probabilistic increment to save Firestore writes.
    """
    if random.random() > SAMPLING_RATE:
        return
    
    db = get_db()
    if not db: return

    try:
        shard_id = int(random.random() * NUM_SHARDS)
        today = datetime.datetime.utcnow().strftime('%Y-%m-%d')
        shard_ref = db.collection('stats').document('global_usage').collection(today).document(str(shard_id))
        
        shard_ref.set({'count': firestore.Increment(int(1/SAMPLING_RATE))}, merge=True)
    except Exception as e:
        print(f"Failed to increment global counter: {e}")

def get_total_global_usage():
    """
    Sum all shards for today.
    """
    coll_ref = get_daily_shard_collection()
    if not coll_ref: return 0

    try:
        shards = coll_ref.get()
        total = 0
        for doc in shards:
            total += doc.to_dict().get('count', 0)
        return total
    except Exception as e:
        print(f"Error reading global usage: {e}")
        return 0
