import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/course_model.dart';
import '../../core/constants/app_constants.dart';

class CourseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>>? _getAdvisingDocRef(String semester) {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('advising')
        .doc(semester.replaceAll(' ', '_'));
  }

  Future<void> saveGeneratedSchedules(
      String semester, List<List<Course>> schedules) async {
    final docRef = _getAdvisingDocRef(semester);
    if (docRef == null) return;

    final scheduleIds = schedules
        .map((schedule) => schedule.map((course) => course.id).toList())
        .toList();

    await docRef.set({'generatedSchedules': scheduleIds}, SetOptions(merge: true));
  }

  Future<List<List<Course>>> loadGeneratedSchedules(String semester) async {
    final docRef = _getAdvisingDocRef(semester);
    if (docRef == null) return [];

    final doc = await docRef.get();
    if (!doc.exists || doc.data() == null) return [];

    final data = doc.data();
    final scheduleIds = List<List<dynamic>>.from(data!['generatedSchedules'] ?? []);

    if (scheduleIds.isEmpty) return [];

    final allCourseIds = scheduleIds.expand((ids) => ids).toSet().toList();
    if (allCourseIds.isEmpty) return [];
    
    final courses = await fetchCoursesByIds(semester, allCourseIds.cast<String>());
    final courseMap = {for (var c in courses) c.id: c};

    List<List<Course>> loadedSchedules = [];
    for (final idList in scheduleIds) {
      final schedule = idList.map((id) => courseMap[id]).whereType<Course>().toList();
      if (schedule.length == idList.length) { 
        loadedSchedules.add(schedule);
      }
    }
    return loadedSchedules;
  }
  
  Future<void> clearGeneratedSchedules(String semester) async {
    final docRef = _getAdvisingDocRef(semester);
    if (docRef == null) return;
    await docRef.update({'generatedSchedules': FieldValue.delete()});
  }

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
      final snapshot = await _firestore.collection('metadata').doc('courses').get();
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
  
  Future<Map<String, List<Course>>> fetchCoursesByCode(
      String semester, List<String> codes) async {
    if (codes.isEmpty) return {};

    try {
      final Map<String, List<Course>> groupedCourses = {};
      for (var i = 0; i < codes.length; i += AppConstants.firestoreWhereInLimit) {
        final batch = codes.skip(i).take(AppConstants.firestoreWhereInLimit).toList();
        
        final snapshot = await _firestore
            .collection('courses_$semester')
            .where('code', whereIn: batch)
            .get();
            
        for (var doc in snapshot.docs) {
          final course = Course.fromFirestore(doc.data(), doc.id);
          if (groupedCourses.containsKey(course.code)) {
            groupedCourses[course.code]!.add(course);
          } else {
            groupedCourses[course.code] = [course];
          }
        }
      }
      return groupedCourses;
    } catch (e) {
      debugPrint('[CourseRepo] Error fetching courses by code: $e');
      rethrow;
    }
  }

  Future<List<Course>> searchCourses(String query, String semester) async {
    if (query.isEmpty) return [];
    try {
      final allCourses = await fetchCourses(semester);
      final List<Course> flattenedCourses = allCourses.values.expand((sections) => sections).toList();
      final lower = query.toLowerCase();
      return flattenedCourses
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

  Future<List<Course>> fetchCoursesByIds(
      String semester, List<String> docIds) async {
    if (docIds.isEmpty) return [];

    try {
      final List<Course> courses = [];
      
      for (var i = 0; i < docIds.length; i += AppConstants.firestoreWhereInLimit) {
        final batch = docIds.skip(i).take(AppConstants.firestoreWhereInLimit).toList();
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
        'completedCourses': FieldValue.arrayRemove([courseId]),
      });

      if (semesterCode != null) {
        final safeSem = semesterCode.replaceAll(' ', '_');
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

      if (semesterCode != null) {
        final safeSem = semesterCode.replaceAll(' ', '_');
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('semesterProgress')
            .doc(safeSem)
            .collection('courses')
            .doc(courseId)
            .delete();

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
