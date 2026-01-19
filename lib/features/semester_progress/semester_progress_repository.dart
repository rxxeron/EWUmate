import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/semester_progress_models.dart';

class SemesterProgressRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference _getCourseDoc(String semesterCode, String courseCode) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('semesterProgress')
        .doc(semesterCode)
        .collection('courses')
        .doc(courseCode);
  }

  /// Streams all courses with marks for a given semester
  Stream<List<CourseMarks>> getSemesterProgressStream(String semesterCode) {
    if (_uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('semesterProgress')
        .doc(semesterCode)
        .collection('courses')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['courseCode'] = doc.id;
            return CourseMarks.fromMap(data);
          }).toList();
        });
  }

  /// Fetches all courses with marks for a given semester
  Future<List<CourseMarks>> fetchSemesterProgress(String semesterCode) async {
    if (_uid == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('semesterProgress')
          .doc(semesterCode)
          .collection('courses')
          .get();

      debugPrint(
        '[SemesterProgressRepo] Fetched ${snapshot.docs.length} courses for $semesterCode',
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['courseCode'] = doc.id;
        return CourseMarks.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error fetching semester progress: $e');
      return [];
    }
  }

  /// Fetches cloud-generated semester summary (predictions, GPA)
  Future<Map<String, dynamic>?> fetchSemesterSummary(
    String semesterCode,
  ) async {
    if (_uid == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('semesterProgress')
          .doc(semesterCode)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      return data?['summary'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error fetching summary: $e');
      return null;
    }
  }

  /// Fetches marks for a single course
  Future<CourseMarks?> fetchCourseMarks(
    String semesterCode,
    String courseCode,
  ) async {
    if (_uid == null) return null;

    try {
      final doc = await _getCourseDoc(semesterCode, courseCode).get();

      if (!doc.exists) {
        debugPrint(
          '[SemesterProgressRepo] Course $courseCode does not exist, returning null',
        );
        return null;
      }

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;
      data['courseCode'] = doc.id;
      debugPrint('[SemesterProgressRepo] Fetched course marks for $courseCode');
      return CourseMarks.fromMap(data);
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error fetching course marks: $e');
      return null;
    }
  }

  /// Initializes a course with empty data if it doesn't exist
  Future<void> initializeCourse(
    String semesterCode,
    String courseCode, {
    String? courseName,
  }) async {
    if (_uid == null) return;

    try {
      final docRef = _getCourseDoc(semesterCode, courseCode);
      final doc = await docRef.get();

      if (!doc.exists) {
        debugPrint('[SemesterProgressRepo] Initializing course $courseCode');
        await docRef.set({
          'courseCode': courseCode,
          'courseName': courseName ?? courseCode,
          'distribution': {},
          'obtained': {'quizzes': [], 'shortQuizzes': []},
          'quizStrategy': 'bestN',
        });
        debugPrint('[SemesterProgressRepo] Course $courseCode initialized');
      } else {
        debugPrint('[SemesterProgressRepo] Course $courseCode already exists');
      }
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error initializing course: $e');
    }
  }

  /// Saves or updates mark distribution for a course
  Future<bool> saveMarkDistribution(
    String semesterCode,
    String courseCode,
    MarkDistribution distribution, {
    String? courseName,
  }) async {
    if (_uid == null) return false;

    try {
      debugPrint('[SemesterProgressRepo] Saving distribution for $courseCode');
      await _getCourseDoc(semesterCode, courseCode).set({
        'distribution': distribution.toMap(),
        'courseName': courseName ?? courseCode,
      }, SetOptions(merge: true));
      debugPrint('[SemesterProgressRepo] Distribution saved for $courseCode');
      return true;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error saving distribution: $e');
      return false;
    }
  }

  /// Saves obtained marks for a category (excluding quizzes)
  Future<bool> saveObtainedMark(
    String semesterCode,
    String courseCode,
    String category,
    double value,
  ) async {
    if (_uid == null) return false;

    try {
      debugPrint(
        '[SemesterProgressRepo] Saving $category=$value for $courseCode',
      );
      await _getCourseDoc(semesterCode, courseCode).set({
        'obtained': {category: value},
      }, SetOptions(merge: true));
      debugPrint('[SemesterProgressRepo] Saved $category for $courseCode');
      return true;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error saving obtained mark: $e');
      return false;
    }
  }

  /// Adds a new quiz mark to the list
  Future<bool> addQuizMark(
    String semesterCode,
    String courseCode,
    double mark,
  ) async {
    if (_uid == null) return false;

    try {
      final docRef = _getCourseDoc(semesterCode, courseCode);

      debugPrint(
        '[SemesterProgressRepo] Adding quiz mark $mark to $courseCode',
      );

      // Use arrayUnion for atomic append
      await docRef.set({
        'obtained': {
          'quizzes': FieldValue.arrayUnion([mark]),
        },
      }, SetOptions(merge: true));

      debugPrint('[SemesterProgressRepo] Quiz mark added to $courseCode');
      return true;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error adding quiz mark: $e');
      return false;
    }
  }

  /// Adds a new short quiz mark to the list
  Future<bool> addShortQuizMark(
    String semesterCode,
    String courseCode,
    double mark,
  ) async {
    if (_uid == null) return false;

    try {
      final docRef = _getCourseDoc(semesterCode, courseCode);

      debugPrint(
        '[SemesterProgressRepo] Adding short quiz mark $mark to $courseCode',
      );

      // Use arrayUnion for atomic append
      await docRef.set({
        'obtained': {
          'shortQuizzes': FieldValue.arrayUnion([mark]),
        },
      }, SetOptions(merge: true));

      debugPrint('[SemesterProgressRepo] Short quiz mark added to $courseCode');
      return true;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error adding short quiz mark: $e');
      return false;
    }
  }

  /// Updates quiz strategy for a course
  Future<bool> saveQuizStrategy(
    String semesterCode,
    String courseCode,
    String strategy,
  ) async {
    if (_uid == null) return false;

    try {
      await _getCourseDoc(
        semesterCode,
        courseCode,
      ).set({'quizStrategy': strategy}, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error saving quiz strategy: $e');
      return false;
    }
  }

  /// Deletes a quiz mark by index
  Future<bool> deleteQuizMark(
    String semesterCode,
    String courseCode,
    int index,
  ) async {
    if (_uid == null) return false;

    try {
      final docRef = _getCourseDoc(semesterCode, courseCode);
      final doc = await docRef.get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      final obtained = data['obtained'] as Map<String, dynamic>? ?? {};
      final quizzes = List<dynamic>.from(obtained['quizzes'] ?? []);

      if (index >= 0 && index < quizzes.length) {
        quizzes.removeAt(index);
        await docRef.update({'obtained.quizzes': quizzes});
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error deleting quiz mark: $e');
      return false;
    }
  }

  /// Deletes a short quiz mark by index
  Future<bool> deleteShortQuizMark(
    String semesterCode,
    String courseCode,
    int index,
  ) async {
    if (_uid == null) return false;

    try {
      final docRef = _getCourseDoc(semesterCode, courseCode);
      final doc = await docRef.get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      final obtained = data['obtained'] as Map<String, dynamic>? ?? {};
      final shortQuizzes = List<dynamic>.from(obtained['shortQuizzes'] ?? []);

      if (index >= 0 && index < shortQuizzes.length) {
        shortQuizzes.removeAt(index);
        await docRef.update({'obtained.shortQuizzes': shortQuizzes});
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[SemesterProgressRepo] Error deleting short quiz mark: $e');
      return false;
    }
  }
}
