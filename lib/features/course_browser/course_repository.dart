import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/course_model.dart';
import '../../core/constants/app_constants.dart';

class CourseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Course>> fetchCourses(String semester) async {
    try {
      debugPrint('[CourseRepo] Fetching from collection: courses_$semester');
      final snapshot = await _firestore.collection('courses_$semester').get();
      debugPrint('[CourseRepo] Found ${snapshot.docs.length} documents');
      return snapshot.docs
          .map((doc) => Course.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('[CourseRepo] Error fetching courses: $e');
      return [];
    }
  }

  Future<List<Course>> searchCourses(String query, String semester) async {
    if (query.isEmpty) return [];
    try {
      // For MVP: Fetch all and filter locally.
      final all = await fetchCourses(semester);
      final lower = query.toLowerCase();
      return all
          .where((c) {
            return c.code.toLowerCase().contains(lower) ||
                c.courseName.toLowerCase().contains(lower);
          })
          .take(50)
          .toList();
    } catch (e) {
      debugPrint('[CourseRepo] Error searching courses: $e');
      return [];
    }
  }

  /// Fetches specific courses by their Firestore document IDs
  /// Uses batch query (whereIn) for optimization - 1 call instead of N calls
  Future<List<Course>> fetchCoursesByIds(
      String semester, List<String> docIds) async {
    if (docIds.isEmpty) return [];

    try {
      debugPrint(
          '[CourseRepo] Fetching ${docIds.length} courses by ID from courses_$semester');

      final List<Course> courses = [];

      // Firestore whereIn limit is 30, so batch if needed
      for (var i = 0;
          i < docIds.length;
          i += AppConstants.firestoreWhereInLimit) {
        final batch =
            docIds.skip(i).take(AppConstants.firestoreWhereInLimit).toList();

        final snapshot = await _firestore
            .collection('courses_$semester')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          courses.add(Course.fromFirestore(doc.data(), doc.id));
        }
      }

      debugPrint(
          '[CourseRepo] Successfully fetched ${courses.length} courses in batch');
      return courses;
    } catch (e) {
      debugPrint('[CourseRepo] Error fetching courses by IDs: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final docSnap = await _firestore.collection('users').doc(user.uid).get();
    if (docSnap.exists) {
      return docSnap.data() ?? {};
    }
    return {};
  }

  Future<void> toggleEnrolled(String courseId, bool shouldEnroll,
      {String? semesterCode, String? courseName}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);

    if (shouldEnroll) {
      await userRef.update({
        'enrolledSections': FieldValue.arrayUnion([courseId]),
        'completedCourses': FieldValue.arrayRemove([courseId]),
      });

      // Also write to semesterProgress for Cloud Function trigger
      if (semesterCode != null) {
        final safeSem = semesterCode.replaceAll(' ', '');
        final courseDoc = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('semesterProgress')
            .doc(safeSem)
            .collection('courses')
            .doc(courseId);

        await courseDoc.set({
          'courseCode': courseId,
          'courseName': courseName ?? courseId,
          'distribution': {},
          'obtained': {'quizzes': [], 'shortQuizzes': []},
          'quizStrategy': 'bestN',
        }, SetOptions(merge: true));

        // Touch parent to trigger schedule generation
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('semesterProgress')
            .doc(safeSem)
            .set({
          'semesterCode': safeSem,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } else {
      await userRef.update({
        'enrolledSections': FieldValue.arrayRemove([courseId]),
      });

      // Also remove from semesterProgress
      if (semesterCode != null) {
        final safeSem = semesterCode.replaceAll(' ', '');
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('semesterProgress')
            .doc(safeSem)
            .collection('courses')
            .doc(courseId)
            .delete();

        // Touch parent to trigger schedule regeneration
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('semesterProgress')
            .doc(safeSem)
            .set({
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> saveGrade(Course course, String semester, String grade,
      String credits, double points) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userRef = _firestore.collection('users').doc(user.uid);

    final resultEntry = {
      'courseId': course.id,
      'courseCode': course.code,
      'courseName': course.courseName,
      'semesterId': semester,
      'credits': credits,
      'grade': grade,
      'point': points,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await userRef.update({
      'completedCourses': FieldValue.arrayUnion([course.id]),
      'enrolledSections': FieldValue.arrayRemove([course.id]),
      'academicResults': FieldValue.arrayUnion([resultEntry]),
    });
  }
}
