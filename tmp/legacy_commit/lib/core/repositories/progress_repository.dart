import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/semester_course_marks.dart';
import '../models/semester_summary.dart';
import '../providers/supabase_provider.dart';
import 'auth_repository.dart';

part 'progress_repository.g.dart';

class ProgressRepository {
  final SupabaseClient _supabase;

  ProgressRepository(this._supabase);

  Future<List<SemesterCourseMarks>> getCourseMarks(
    String userId,
    String semesterCode,
  ) async {
    final response = await _supabase
        .from('semester_course_marks')
        .select()
        .eq('user_id', userId)
        .eq('semester_code', semesterCode);

    return (response as List)
        .map((e) => SemesterCourseMarks.fromJson(e))
        .toList();
  }

  Future<void> updateCourseMarks(SemesterCourseMarks marks) async {
    await _supabase
        .from('semester_course_marks')
        .update(marks.toJson())
        .eq('id', marks.id);
  }

  Future<List<SemesterSummary>> getSemesterSummaries(String userId) async {
    final response = await _supabase
        .from('semester_summaries')
        .select()
        .eq('user_id', userId)
        .order('semester_code', ascending: false);

    return (response as List).map((e) => SemesterSummary.fromJson(e)).toList();
  }

  Future<List<SemesterSummary>> getSemesterSummariesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    final response = await _supabase
        .from('semester_summaries')
        .select()
        .inFilter('id', ids);

    // Maintain the chronological order from the profile list
    final Map<String, SemesterSummary> summaryMap = {
      for (var e in (response as List)) 
        (e['id'] as String): SemesterSummary.fromJson(e)
    };

    return ids
        .where((id) => summaryMap.containsKey(id))
        .map((id) => summaryMap[id]!)
        .toList();
  }

  Future<Map<String, dynamic>?> getProgramDetails(String programCode) async {
    final response = await _supabase
        .from('programs')
        .select()
        .eq('program_code', programCode)
        .maybeSingle();
    return response;
  }
}

@riverpod
ProgressRepository progressRepository(ProgressRepositoryRef ref) {
  return ProgressRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<List<SemesterCourseMarks>> currentSemesterMarks(
  CurrentSemesterMarksRef ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  // Hardcoded Spring2026 for now, can be read from active semester state
  final marks = await ref
      .watch(progressRepositoryProvider)
      .getCourseMarks(user.id, 'Spring2026');
      
  // Hide corrupted rows (e.g., UUIDs accidentally saved as course_code)
  return marks.where((m) => m.courseCode.length <= 15 && !m.courseCode.contains('-')).toList();
}

@riverpod
Future<List<SemesterSummary>> allSemesterSummaries(
  AllSemesterSummariesRef ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  return ref.watch(progressRepositoryProvider).getSemesterSummaries(user.id);
}

// Providers for programDetails are now moved to core/providers/academic_providers.dart
