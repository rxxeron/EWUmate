from firebase_functions import firestore_fn, https_fn
from firebase_admin import messaging

# @firestore_fn.on_document_updated(document="config/app_info")
# def on_app_info_updated(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
#     """
#     MOVED TO TYPESCRIPT (functions-node/src/index.ts)
#     """
#     pass


# @firestore_fn.on_document_created(document="admin_broadcasts/{broadcastId}")
# def on_broadcast_created(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
#     """
#     MOVED TO TYPESCRIPT (functions-node/src/index.ts)
#     to support Cloud Tasks scheduling.
#     """
#     pass

