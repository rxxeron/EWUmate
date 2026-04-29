
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/semester_course_marks.dart';
import '../models/semester_summary.dart';
import '../providers/supabase_provider.dart';
import '../services/cache_service.dart';
import 'auth_repository.dart';

part 'progress_repository.g.dart';

class ProgressRepository {
  final SupabaseClient _supabase;
  final CacheService _cache;

  ProgressRepository(this._supabase, this._cache);

  Future<List<SemesterCourseMarks>> getCourseMarks(
    String userId,
    String semesterCode,
  ) async {
    try {
      final response = await _supabase
          .from('semester_course_marks')
          .select()
          .eq('user_id', userId)
          .eq('semester_code', semesterCode);

      final marks = (response as List)
          .map((e) => SemesterCourseMarks.fromJson(e))
          .toList();
      
      _cache.setMapData('semester_progress_box', 'marks_${userId}_$semesterCode', 
          {'data': marks.map((m) => m.toJson()).toList()});
      return marks;
    } catch (e) {
      if (kDebugMode) debugPrint('[ProgressRepo] getCourseMarks fallback: $e');
      final cached = _cache.getMapData('semester_progress_box', 'marks_${userId}_$semesterCode');
      if (cached != null && cached['data'] != null) {
        return (cached['data'] as List)
            .map((e) => SemesterCourseMarks.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    }
  }

  Future<void> updateCourseMarks(SemesterCourseMarks marks) async {
    await _supabase
        .from('semester_course_marks')
        .update(marks.toJson())
        .eq('id', marks.id);
  }

  Future<List<SemesterSummary>> getSemesterSummaries(String userId) async {
    try {
      final response = await _supabase
          .from('semester_summaries')
          .select()
          .eq('user_id', userId)
          .order('semester_code', ascending: false);

      final summaries = (response as List).map((e) => SemesterSummary.fromJson(e)).toList();
      _cache.setMapData('dashboard_box', 'summaries_$userId', 
          {'data': summaries.map((s) => s.toJson()).toList()});
      return summaries;
    } catch (e) {
      if (kDebugMode) debugPrint('[ProgressRepo] getSemesterSummaries fallback: $e');
      final cached = _cache.getMapData('dashboard_box', 'summaries_$userId');
      if (cached != null && cached['data'] != null) {
        return (cached['data'] as List)
            .map((e) => SemesterSummary.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    }
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
    try {
      final response = await _supabase
          .from('programs')
          .select()
          .eq('program_code', programCode)
          .maybeSingle();
      
      if (response != null) {
        _cache.setMapData('dashboard_box', 'program_$programCode', response);
      }
      return response;
    } catch (e) {
      return _cache.getMapData('dashboard_box', 'program_$programCode');
    }
  }
}

@riverpod
ProgressRepository progressRepository(ProgressRepositoryRef ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final cache = ref.watch(cacheServiceProvider);
  return ProgressRepository(supabase, cache);
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
