import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate('c:/Users/ibnea/Downloads/Mobile App/Mobile App/flutter_v2_new/functions/ewu-stu-togo-firebase-adminsdk-hsk4i-705a305f2a.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

collections = db.collections()
for coll in collections:
    if coll.id.startswith('courses_'):
        print(f'Found collection: {coll.id}')
    if coll.id == 'metadata':
        print(f'Found metadata collection')
        meta_doc = db.collection('metadata').document('courses').get()
        if meta_doc.exists:
            print(f'  Metadata courses exists with {len(meta_doc.to_dict().get("list", []))} items')
        else:
            print(f'  Metadata courses does NOT exist')
