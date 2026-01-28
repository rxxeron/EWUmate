import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/notification_model.dart';
import 'dart:async';

class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Simplified: Get personal only for now, or use StreamZip if multiple.
  // To avoid complex merge logic without rxdart, we will expose them and merge in UI.

  Stream<List<AppNotification>> getPersonalNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<AppNotification>> getBroadcasts() {
    return _db
        .collection('admin_broadcasts')
        .orderBy('sentAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['type'] = 'broadcast';
              if (data['sentAt'] != null) data['createdAt'] = data['sentAt'];
              return AppNotification.fromMap(data, d.id);
            }).toList());
  }

  Future<void> markAsRead(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Check if it's personal
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(id)
          .update({'read': true});
    } catch (e) {
      // Might be broadcast, can't mark read in fetching coll.
      // Need a local 'read_broadcasts' coll. Skipping for MVP.
    }
  }
}
