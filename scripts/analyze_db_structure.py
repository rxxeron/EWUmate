import firebase_admin
from firebase_admin import credentials, firestore
import json
import os

# Path to your service account key
KEY_PATH = "config/serviceAccountKey.json"

def analyze_database():
    if not os.path.exists(KEY_PATH):
        print(f"❌ Error: Service Account Key not found at: {KEY_PATH}")
        print("Please download it from Firebase Console -> Project Settings -> Service Accounts")
        return

    # Initialize Firebase
    if not firebase_admin._apps:
        cred = credentials.Certificate(KEY_PATH)
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    print("\n🔍 Analyzing Firestore Database Structure...\n")

    collections = db.collections()
    
    structure = {}

    for collection in collections:
        col_name = collection.id
        print(f"📂 Collection: {col_name}")
        
        # Get up to 3 documents to sample structure
        docs = list(collection.limit(3).stream())
        
        if not docs:
            print("   (Empty)")
            structure[col_name] = {"count": 0, "sample": None}
            continue

        sample_data = docs[0].to_dict()
        doc_count = 0 # We won't count all to save reads, just indicate it has data
        
        print(f"   found documents... (ID: {docs[0].id})")
        print(f"   Fields: {list(sample_data.keys())}")
        
        # Check subcollections for the first doc
        subcollections = list(docs[0].reference.collections())
        sub_names = [sub.id for sub in subcollections]
        if sub_names:
            print(f"   Subcollections: {sub_names}")
            
        print("-" * 40)

if __name__ == "__main__":
    analyze_database()
