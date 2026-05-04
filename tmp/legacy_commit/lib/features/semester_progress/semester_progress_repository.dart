import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final semesterProgressRepositoryProvider = Provider((ref) => SemesterProgressRepository(Supabase.instance.client));

class SemesterProgressRepository {
  final SupabaseClient _supabase;
  SemesterProgressRepository(this._supabase);

  // Need to get active semester
  Future<String> getActiveSemesterCode() async {
    final config = await _supabase.from('active_semester').select().limit(1).maybeSingle();
    return config?['current_semester_code'] ?? 'Spring2026';
  }

  // Gets both enrollments and course marks
  Future<List<Map<String, dynamic>>> getSemesterProgressData(String userId, String semesterCode) async {
    // 1. Get Enrollments
    final enrollments = await _supabase
        .from('enrollments')
        .select('course_code')
        .eq('user_id', userId)
        .eq('semester_code', semesterCode);

    final enrolledCourseCodes = (enrollments as List).map((e) => e['course_code'] as String).toList();

    if (enrolledCourseCodes.isEmpty) return [];

    // 2. Get Course Marks
    final marksRes = await _supabase
        .from('semester_course_marks')
        .select('*')
        .eq('user_id', userId)
        .eq('semester_code', semesterCode)
        .inFilter('course_code', enrolledCourseCodes);
    
    final marksData = List<Map<String, dynamic>>.from(marksRes);

    // Merge so that every enrolled course has a map, even if no marks data exists yet
    List<Map<String, dynamic>> progressData = [];
    for (var code in enrolledCourseCodes) {
      final existingMark = marksData.firstWhere(
        (m) => m['course_code'] == code, 
        orElse: () => {
          'course_code': code,
          'is_new': true, // indicates we need to insert it on save
        }
      );
      progressData.add(existingMark);
    }

    return progressData;
  }

  Future<void> saveCourseMarks(String userId, String semesterCode, Map<String, dynamic> data) async {
    // check if it's new
    final isNew = data['is_new'] == true;
    data.remove('is_new');

    data['user_id'] = userId;
    data['semester_code'] = semesterCode;
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();

    if (isNew) {
      await _supabase.from('semester_course_marks').insert(data);
    } else {
      await _supabase.from('semester_course_marks')
          .update(data)
          .eq('user_id', userId)
          .eq('semester_code', semesterCode)
          .eq('course_code', data['course_code']);
    }
  }
}
