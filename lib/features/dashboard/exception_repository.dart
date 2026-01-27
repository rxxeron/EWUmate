import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExceptionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Fetch all active exceptions for the user
  Future<List<Map<String, dynamic>>> fetchExceptions() async {
    if (_uid == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('schedule_exceptions')
          .get();

      return snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a cancellation exception
  Future<void> addCancellation(String date, String courseCode,
      {bool pendingMakeup = false}) async {
    if (_uid == null) return;
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('schedule_exceptions')
        .add({
      'type': 'cancel',
      'date': date,
      'courseCode': courseCode,
      'pendingMakeup': pendingMakeup,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add a makeup class exception
  Future<void> addMakeupClass({
    required String date,
    required String courseCode,
    required String courseName,
    required String startTime,
    required String endTime,
    required String room,
  }) async {
    if (_uid == null) return;
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('schedule_exceptions')
        .add({
      'type': 'makeup',
      'date': date,
      'courseCode': courseCode,
      'courseName': courseName,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing makeup class exception
  Future<void> updateMakeupClass({
    required String id,
    required String date,
    required String startTime,
    required String endTime,
    required String room,
  }) async {
    if (_uid == null) return;
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('schedule_exceptions')
        .doc(id)
        .update({
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove an exception (e.g. undo cancel)
  Future<void> removeException(String id) async {
    if (_uid == null) return;
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('schedule_exceptions')
        .doc(id)
        .delete();
  }

  Future<String?> findExceptionId(
      String date, String courseCode, String type) async {
    if (_uid == null) return null;
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('schedule_exceptions')
        .where('date', isEqualTo: date)
        .where('courseCode', isEqualTo: courseCode)
        .where('type', isEqualTo: type)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }
    return null;
  }
}
