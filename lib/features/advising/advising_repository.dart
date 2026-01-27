import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/course_model.dart';

class AdvisingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save a generated plan
  Future<void> saveGeneratedPlan({
    required String semester,
    required List<String> inputCodes,
    required List<List<dynamic>>
        combinations, // List of combinations (each is list of maps)
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Store just the essential data to reconstruct
      // We need to store SECTION IDs for each combination.
      // The `combinations` from cloud function has full objects with 'id'.

      final simplifiedCombinations = combinations.map((combo) {
        return combo.map((section) => section['id']).toList();
      }).toList();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('advising_plans')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'semester': semester,
        'inputCodes': inputCodes,
        'combinations': simplifiedCombinations,
        // We might want to store more metadata for preview (e.g. number of options)
        'optionCount': combinations.length,
      });
    } catch (e) {
      // print('Error saving plan: $e');
      rethrow;
    }
  }

  // Fetch past plans
  Stream<List<Map<String, dynamic>>> getParamsStream(String semester) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('advising_plans')
        .where('semester', isEqualTo: semester)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // Validate a saved schedule by fetching fresh data
  Future<List<Course>> validateSchedule(
      String semester, List<String> sectionIds) async {
    if (sectionIds.isEmpty) return [];

    // We can reuse CourseRepository logic here, or re-implement fetching by IDs.
    // Since we need to be robust, let's query directly.
    try {
      final List<Course> freshCourses = [];
      // Batch fetch (limit 30)
      for (var i = 0; i < sectionIds.length; i += 30) {
        final end = (i + 30 < sectionIds.length) ? i + 30 : sectionIds.length;
        final batch = sectionIds.sublist(i, end);

        final snapshot = await _firestore
            .collection('courses_$semester')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in snapshot.docs) {
          freshCourses.add(Course.fromFirestore(doc.data(), doc.id));
        }
      }
      return freshCourses;
    } catch (e) {
      // print('Error validating schedule: $e');
      return [];
    }
  }

  // Save a specific manual plan or a selected option from generator
  Future<void> saveManualPlan(String semester, List<String> sectionIds) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('planner')
        .doc(semester.replaceAll(' ', ''))
        .set({
      'sectionIds': sectionIds,
      'semester': semester,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Fetch the saved planner draft
  Future<List<String>> getManualPlanIds(String semester) async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('planner')
        .doc(semester.replaceAll(' ', ''))
        .get();
    if (!doc.exists) return [];
    return List<String>.from(doc.data()?['sectionIds'] ?? []);
  }

  // Finalize Enrollment: Move from Planner to Official Enrolled Sections
  Future<void> finalizeEnrollment(String semester) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final planIds = await getManualPlanIds(semester);
    if (planIds.isEmpty) return;

    await _firestore.collection('users').doc(user.uid).update({
      'enrolledSections': planIds,
    });
  }
}
