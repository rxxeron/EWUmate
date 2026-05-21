
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/semester_course_marks.dart';
import '../models/semester_summary.dart';
import '../providers/supabase_provider.dart';
import '../services/cache_service.dart';
import 'auth_repository.dart';

import 'package:ewumate/core/providers/academic_providers.dart';
import 'package:ewumate/core/utils/course_utils.dart';


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
      final safeSem = CourseUtils.cleanSemester(semesterCode);
      final spaceSem = semesterCode.replaceAllMapped(RegExp(r'([a-zA-Z]+)(\d+)'), (m) => '${m[1]} ${m[2]}');
      
      // 1. Fetch Enrollments first to know what SHOULD be there
      final enrollmentsRes = await _supabase
          .from('enrollments')
          .select('course_code')
          .eq('user_id', userId)
          .inFilter('semester_code', [semesterCode, safeSem, spaceSem, semesterCode.toLowerCase(), semesterCode.replaceAll(' ', '')]);
      
      final enrolledCodes = (enrollmentsRes as List).map((e) => e['course_code'] as String).toList();

      // 2. Fetch existing marks
      final response = await _supabase
          .from('semester_course_marks')
          .select()
          .eq('user_id', userId)
          .inFilter('semester_code', [semesterCode, safeSem, spaceSem, semesterCode.toLowerCase(), semesterCode.replaceAll(' ', '')]);

      final List<Map<String, dynamic>> rawMarks = List<Map<String, dynamic>>.from(response as List);
      
      // 3. Merge: Ensure every enrolled course has a marks object
      final List<SemesterCourseMarks> finalMarks = [];
      for (var code in enrolledCodes) {
        final normalizedCode = CourseUtils.normalize(code);
        final existing = rawMarks.firstWhere(
          (m) => CourseUtils.normalize(m['course_code'] as String) == normalizedCode,
          orElse: () => {
            'user_id': userId,
            'semester_code': safeSem,
            'course_code': code,
            'id': 'new_$normalizedCode',
          }
        );
        finalMarks.add(SemesterCourseMarks.fromJson(existing));
      }

      // 4. Add any marks that exist but aren't in enrollments (safety)
      for (var m in rawMarks) {
        final normalizedCode = CourseUtils.normalize(m['course_code'] as String);
        if (!finalMarks.any((f) => CourseUtils.normalize(f.courseCode) == normalizedCode)) {
          finalMarks.add(SemesterCourseMarks.fromJson(m));
        }
      }
      
      _cache.setMapData('semester_progress_box', 'marks_${userId}_$semesterCode', 
          {'data': finalMarks.map((m) => m.toJson()).toList()});
      return finalMarks;
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
    final data = marks.toJson();
    // Normalize course and semester codes
    data['course_code'] = CourseUtils.normalize(marks.courseCode);
    data['semester_code'] = CourseUtils.cleanSemester(marks.semesterCode);
    // Remove temporary ID to allow upsert logic to use unique constraint
    if (data['id'] != null && data['id'].toString().startsWith('new_')) {
      data.remove('id');
    }

    try {
      await _supabase
          .from('semester_course_marks')
          .upsert(data, onConflict: 'user_id,semester_code,course_code');
    } catch (e) {
      if (kDebugMode) debugPrint('[ProgressRepo] Offline detected. Enqueuing update: $e');
      // ENQUEUE FOR SYNC
      await _cache.enqueueMutation(marks.userId, {
        'type': 'progress_update',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    // Update Cache to prevent "All data gone" flicker
    final cacheKey = 'marks_${marks.userId}_${marks.semesterCode}';
    final cached = _cache.getMapData('semester_progress_box', cacheKey) ?? {'data': []};
    final list = List<Map<String, dynamic>>.from(cached['data'] ?? []);
    
    final normalizedCode = data['course_code'];
    final index = list.indexWhere((m) => (m['course_code'] as String).toUpperCase().replaceAll(' ', '') == normalizedCode);
    if (index != -1) {
      list[index] = data;
    } else {
      list.add(data);
    }
    _cache.setMapData('semester_progress_box', cacheKey, {'data': list});
    
    // Trigger background credit recalculation (only if online)
    _supabase.functions.invoke('sync-academic-stats').catchError((_) => null);
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
Stream<List<SemesterCourseMarks>> currentSemesterMarks(
  CurrentSemesterMarksRef ref,
) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield [];
    return;
  }
  
  final semCode = ref.watch(currentSemesterCodeProvider).value ?? 'Summer2026';
  final repo = ref.watch(progressRepositoryProvider);
  final cacheKey = 'marks_${user.id}_$semCode';

  // 1. Yield cache immediately for instant offline use
  final cached = ref.read(cacheServiceProvider).getMapData('semester_progress_box', cacheKey);
  if (cached != null && cached['data'] != null) {
    final list = (cached['data'] as List)
        .map((e) => SemesterCourseMarks.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.courseCode.length <= 15)
        .toList();
    yield list;
  }

  // 2. Attempt online fetch in background exactly once
  try {
    final marks = await repo.getCourseMarks(user.id, semCode).timeout(const Duration(seconds: 12));
    yield marks.where((m) => m.courseCode.length <= 15).toList();
  } catch (e) {
    if (kDebugMode) debugPrint('[currentSemesterMarks] Offline or fetch failed: $e');
  }
}

@riverpod
Stream<List<SemesterSummary>> allSemesterSummaries(
  AllSemesterSummariesRef ref,
) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield [];
    return;
  }
  
  final repo = ref.watch(progressRepositoryProvider);
  final cacheKey = 'summaries_${user.id}';

  // 1. Yield cache immediately
  final cached = ref.read(cacheServiceProvider).getMapData('dashboard_box', cacheKey);
  if (cached != null && cached['data'] != null) {
    final list = (cached['data'] as List)
        .map((e) => SemesterSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    yield list;
  }

  // 2. Attempt online fetch in background exactly once
  try {
    final summaries = await repo.getSemesterSummaries(user.id).timeout(const Duration(seconds: 12));
    yield summaries;
  } catch (e) {
    if (kDebugMode) debugPrint('[allSemesterSummaries] Offline or fetch failed: $e');
  }
}


// Providers for programDetails are now moved to core/providers/academic_providers.dart
