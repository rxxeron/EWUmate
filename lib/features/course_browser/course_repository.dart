import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/course_model.dart';
import '../../core/constants/app_constants.dart';

class CourseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // --- NEW: Backend Schedule Generation ---

  Future<String?> triggerScheduleGeneration(String semester,
      List<String> courseCodes, Map<String, dynamic> filters) async {
    try {
      final callable = _functions.httpsCallable('generate_schedules_kickoff');
      final result = await callable.call({
        'semester': semester,
        'courses': courseCodes,
        'filters': filters,
      });
      return result.data['generationId'];
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud function failed: ${e.code} ${e.message}');
      rethrow;
    }
  }

  Stream<List<List<Course>>> streamGeneratedSchedules(String generationId) {
    return _firestore
        .collection('schedule_generations')
        .doc(generationId)
        .snapshots()
        .map((doc) => _parseGeneration(doc.data(), doc.id));
  }

  Stream<List<List<Course>>> streamLatestGeneratedSchedules() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('schedule_generations')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return [];
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final aTime = a.data()['createdAt'];
        final bTime = b.data()['createdAt'];
        return _compareFirestoreTimes(bTime, aTime);
      });
      final latest = docs.first;
      return _parseGeneration(latest.data(), latest.id);
    });
  }

  int _compareFirestoreTimes(dynamic aTime, dynamic bTime) {
    final aValue = _toMillis(aTime);
    final bValue = _toMillis(bTime);
    return aValue.compareTo(bValue);
  }

  int _toMillis(dynamic value) {
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }
    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }
    return 0;
  }

  List<List<Course>> _parseGeneration(Map<String, dynamic>? data, String id) {
    if (data == null) return [];

    final combinations = List<dynamic>.from(data['combinations'] ?? []);
    List<List<Course>> resultSchedules = [];

    for (final scheduleItem in combinations) {
      // New format: each scheduleItem is a map with 'scheduleId' and 'sections' (map of sections)
      if (scheduleItem is Map<String, dynamic>) {
        final sections = scheduleItem['sections'] as Map<String, dynamic>?;
        if (sections != null) {
          List<Course> schedule = [];
          // Convert sections map to list
          final sectionsList = sections.values.toList();
          for (final courseData in sectionsList) {
            if (courseData is Map<String, dynamic>) {
              schedule.add(Course.fromFirestore(courseData, courseData['id'] ?? ''));
            }
          }
          if (schedule.isNotEmpty) {
            resultSchedules.add(schedule);
          }
        }
      } else if (scheduleItem is List) {
        // Legacy format: array of sections (for backwards compatibility)
        List<Course> schedule = [];
        for (final courseData in scheduleItem) {
          if (courseData is Map<String, dynamic>) {
            schedule.add(Course.fromFirestore(courseData, courseData['id'] ?? ''));
          }
        }
        if (schedule.isNotEmpty) {
          resultSchedules.add(schedule);
        }
      }
    }
    return resultSchedules;
  }

  Future<void> clearAllGeneratedSchedules() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final query = _firestore
        .collection('schedule_generations')
        .where('userId', isEqualTo: user.uid);

    final batch = _firestore.batch();
    final snapshot = await query.get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- RESTORED METHODS ---

  Future<Map<String, dynamic>> fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final docSnap = await _firestore.collection('users').doc(user.uid).get();
    return docSnap.data() ?? {};
  }

  Future<void> toggleEnrolled(String courseId, bool shouldEnroll,
      {String? semesterCode, String? courseName}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);

    if (shouldEnroll) {
      await userRef.update({
        'enrolledSections': FieldValue.arrayUnion([courseId]),
      });
    } else {
      await userRef.update({
        'enrolledSections': FieldValue.arrayRemove([courseId]),
      });
    }
  }

  Future<List<Course>> fetchCoursesByIds(
      String semester, List<String> docIds) async {
    if (docIds.isEmpty) return [];

    try {
      final List<Course> courses = [];

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
      return courses;
    } catch (e) {
      debugPrint('[CourseRepo] Error fetching courses by IDs: $e');
      return [];
    }
  }

  // --- Existing Methods ---

  Future<Map<String, List<Course>>> fetchCourses(String semester) async {
    try {
      final snapshot = await _firestore.collection('courses_$semester').get();

      final Map<String, List<Course>> groupedCourses = {};
      for (var doc in snapshot.docs) {
        final course = Course.fromFirestore(doc.data(), doc.id);
        if (groupedCourses.containsKey(course.code)) {
          groupedCourses[course.code]!.add(course);
        } else {
          groupedCourses[course.code] = [course];
        }
      }
      return groupedCourses;
    } catch (e) {
      debugPrint('[CourseRepo] Error fetching courses: $e');
      rethrow;
    }
  }

  Future<List<String>> fetchAllCourseCodes() async {
    try {
      final snapshot =
          await _firestore.collection('metadata').doc('courses').get();
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data.containsKey('list')) {
          return List<String>.from(data['list'].map((item) => item['code']));
        }
      }
      return [];
    } catch (e) {
      debugPrint('[CourseRepo] Error fetching all course codes: $e');
      rethrow;
    }
  }
}
