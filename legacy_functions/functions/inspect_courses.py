import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate('c:/Users/ibnea/Downloads/Mobile App/Mobile App/flutter_v2_new/functions/ewu-stu-togo-firebase-adminsdk-hsk4i-705a305f2a.json')
try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app(cred)
db = firestore.client()

print("Fetching metadata/courses...")
doc = db.collection('metadata').doc('courses').get()
if doc.exists:
    data = doc.to_dict()
    print(f"Metadata found! Total entries: {len(data)}")
    # Print first 10 entries to check format
    keys = list(data.keys())[:10]
    for k in keys:
        print(f"'{k}': '{data[k]}'")
else:
    print("Document 'metadata/courses' does NOT exist.")
