import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/course_model.dart';
import '../../core/services/azure_functions_service.dart';

class CourseRepository {
  final _supabase = Supabase.instance.client;

  // --- Schedule Generation via Azure Function ---

  Future<String?> triggerScheduleGeneration(String semester,
      List<String> courseCodes, Map<String, dynamic> filters) async {
    try {
      final result = await AzureFunctionsService().generateSchedules(
        semester: semester,
        courses: courseCodes,
        filters: filters,
      );
      return result['generationId'] as String?;
    } catch (e) {
      debugPrint('[CourseRepo] Schedule generation error: $e');
      return null;
    }
  }

  Stream<List<List<Course>>> streamGeneratedSchedules(String generationId) {
    // Realtime stream for schedule_generations
    return _supabase
        .from('schedule_generations')
        .stream(primaryKey: ['id'])
        .eq('id', generationId)
        .map((data) => data.isNotEmpty
            ? _parseGeneration(data.first, data.first['id'])
            : []);
  }

  Stream<List<List<Course>>> streamLatestGeneratedSchedules() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('schedule_generations')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .map((data) => data.isNotEmpty
            ? _parseGeneration(data.first, data.first['id'])
            : []);
  }

  List<List<Course>> _parseGeneration(Map<String, dynamic>? data, String id) {
    if (data == null) return [];

    final combinations = List<dynamic>.from(data['combinations'] ?? []);
    List<List<Course>> resultSchedules = [];

    for (final scheduleItem in combinations) {
      if (scheduleItem is Map<String, dynamic>) {
        final sections = scheduleItem['sections'] as Map<String, dynamic>?;
        if (sections != null) {
          List<Course> schedule = [];
          final sectionsList = sections.values.toList();
          for (final courseData in sectionsList) {
            if (courseData is Map<String, dynamic>) {
              schedule
                  .add(Course.fromSupabase(courseData, courseData['id'] ?? ''));
            }
          }
          if (schedule.isNotEmpty) {
            resultSchedules.add(schedule);
          }
        }
      }
    }
    return resultSchedules;
  }

  Future<void> clearAllGeneratedSchedules() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('schedule_generations')
        .delete()
        .eq('user_id', user.id);
  }

  // --- RESTORED METHODS ---

  Future<Map<String, dynamic>> fetchUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};

    final data =
        await _supabase.from('profiles').select().eq('id', user.id).single();
    return data;
  }

  Future<void> toggleEnrolled(String courseId, bool shouldEnroll,
      {String? semesterCode, String? courseName}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Fetch current enrolled list
    final profile = await fetchUserData();
    List<String> enrolled =
        List<String>.from(profile['enrolled_sections'] ?? []);

    if (shouldEnroll) {
      if (!enrolled.contains(courseId)) enrolled.add(courseId);
    } else {
      enrolled.remove(courseId);
    }

    await _supabase
        .from('profiles')
        .update({'enrolled_sections': enrolled}).eq('id', user.id);
  }

  Future<List<Course>> fetchCoursesByIds(
      String semester, List<String> docIds) async {
    if (docIds.isEmpty) return [];

    try {
      final data = await _supabase
          .from('courses')
          .select()
          .eq('semester', semester)
          .inFilter('doc_id', docIds);

      return (data as List)
          .map((d) => Course.fromSupabase(d, d['id']))
          .toList();
    } catch (e) {
      debugPrint('[CourseRepo] Error fetching courses by IDs: $e');
      return [];
    }
  }

  Future<Map<String, List<Course>>> fetchCourses(String semester) async {
    try {
      final data =
          await _supabase.from('courses').select().eq('semester', semester);

      final Map<String, List<Course>> groupedCourses = {};
      for (var d in (data as List)) {
        final course = Course.fromSupabase(d, d['id']);
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
      final data = await _supabase.from('course_metadata').select('code');

      return (data as List).map((item) => item['code'].toString()).toList();
    } catch (e) {
      debugPrint('[CourseRepo] Error fetching all course codes: $e');
      rethrow;
    }
  }
}
