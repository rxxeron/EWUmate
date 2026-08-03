import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/cache_service.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/utils/course_utils.dart';

final semesterProgressRepositoryProvider = Provider((ref) => SemesterProgressRepository(
  Supabase.instance.client,
  ref.watch(cacheServiceProvider)
));

class SemesterProgressRepository {
  final SupabaseClient _supabase;
  final CacheService _cache;
  SemesterProgressRepository(this._supabase, this._cache);

  Future<String> getActiveSemesterCode() async {
    try {
      final config = await _supabase.from('active_semester').select().limit(1).maybeSingle();
      final code = config?['current_semester_code'] ?? 'Spring2026';
      _cache.setMapData('semester_progress_box', 'active_semester_code', {'code': code});
      return code;
    } catch(e) {
      final cached = _cache.getMapData('semester_progress_box', 'active_semester_code');
      return cached?['code'] ?? 'Spring2026';
    }
  }

  Future<List<Map<String, dynamic>>> getSemesterProgressData(String userId, String semesterCode) async {
    final cacheKey = 'marks_${userId}_$semesterCode';
    
    // 1. Try cache first
    final cached = _cache.getMapData('semester_progress_box', cacheKey);
    if (cached != null && cached['data'] != null) {
      // Trigger background sync
      _fetchProgressAndCache(userId, semesterCode, cacheKey);
      return List<Map<String, dynamic>>.from(cached['data']);
    }

    return await _fetchProgressAndCache(userId, semesterCode, cacheKey);
  }

  Future<List<Map<String, dynamic>>> _fetchProgressAndCache(String userId, String semesterCode, String cacheKey) async {
    try {
      final safeSem = CourseUtils.cleanSemester(semesterCode);
      final spaceSem = semesterCode.replaceAllMapped(RegExp(r'([a-zA-Z]+)(\d+)'), (m) => '${m[1]} ${m[2]}');
      
      if (kDebugMode) {
        print('[SemesterProgress] Fetching for $userId, Sem: $semesterCode, Safe: $safeSem');
      }

      final enrollments = await _supabase
          .from('enrollments')
          .select('course_code')
          .eq('user_id', userId)
          .inFilter('semester_code', [semesterCode, safeSem, spaceSem, semesterCode.toLowerCase(), semesterCode.replaceAll(' ', '')]);

      final enrolledCourseCodes = (enrollments as List).map((e) => e['course_code'] as String).toList();
      
      if (kDebugMode) {
        print('[SemesterProgress] Found ${enrolledCourseCodes.length} enrollments: $enrolledCourseCodes');
      }

      final marksRes = await _supabase
          .from('semester_course_marks')
          .select('*')
          .eq('user_id', userId)
          .inFilter('semester_code', [
            semesterCode, 
            CourseUtils.cleanSemester(semesterCode), 
            semesterCode.toLowerCase(),
            semesterCode.replaceAll(' ', ''),
            spaceSem
          ]);
      
      final marksData = List<Map<String, dynamic>>.from(marksRes);

      // 3. Merge pending mutations from sync queue to prevent race conditions
      final queue = _cache.getSyncQueue(userId);
      final pendingMarks = queue
          .where((item) => item['action'] == 'save_course_marks' && item['semesterCode'] == semesterCode)
          .map((item) => Map<String, dynamic>.from(item['data']))
          .toList();

      for (var pending in pendingMarks) {
        final code = (pending['course_code'] as String).toUpperCase().replaceAll(' ', '');
        final index = marksData.indexWhere((m) => (m['course_code'] as String).toUpperCase().replaceAll(' ', '') == code);
        if (index != -1) {
          marksData[index] = {...marksData[index], ...pending};
        } else {
          marksData.add(pending);
        }
      }

      // 4. Build final list, prioritizing enrollments but including any existing marks
      List<Map<String, dynamic>> progressData = [];
      
      // First, add all enrolled courses
      for (var code in enrolledCourseCodes) {
        final normalizedCode = code.toUpperCase().replaceAll(' ', '');
        final existingMark = marksData.firstWhere(
          (m) => (m['course_code'] as String).toUpperCase().replaceAll(' ', '') == normalizedCode, 
          orElse: () => <String, dynamic>{
            'id': 'new_$normalizedCode', 
            'user_id': userId,
            'semester_code': semesterCode,
            'course_code': code,
            'is_new': true,
          }
        );
        progressData.add(existingMark);
      }

      // Second, add any extra marks that aren't in enrollments (to prevent "disappearing" data)
      for (var mark in marksData) {
        final normalizedCode = (mark['course_code'] as String).toUpperCase().replaceAll(' ', '');
        if (!progressData.any((p) => (p['course_code'] as String).toUpperCase().replaceAll(' ', '') == normalizedCode)) {
          progressData.add(mark);
        }
      }
      
      // Update Cache
      _cache.setMapData('semester_progress_box', cacheKey, {'data': progressData});
      
      return progressData;
    } catch (e) {
      if (kDebugMode) debugPrint('[SemesterProgress] Network fetch failed: $e');
      return [];
    }
  }

  Future<void> saveCourseMarks(String userId, String semesterCode, Map<String, dynamic> data) async {
    try {
      // Use UPSERT for robustness (handles both insert and update automatically)
      // We must remove the temporary 'new_' ID if it exists
      if (data['id'] != null && data['id'].toString().startsWith('new_')) {
        data.remove('id');
      }

      // Normalize course code
      if (data['course_code'] != null) {
        data['course_code'] = (data['course_code'] as String).toUpperCase().replaceAll(' ', '');
      }

      // Remove UI-only flags before saving to DB
      data.remove('is_new');

      final res = await _supabase.from('semester_course_marks')
          .upsert(
            {...data, 'semester_code': CourseUtils.cleanSemester(semesterCode)}, 
            onConflict: 'user_id,semester_code,course_code'
          )
          .select()
          .single();
      
      _updateProgressCache(userId, semesterCode, res);
      // Trigger background credit recalculation
      _supabase.functions.invoke('sync-academic-stats').catchError((_) => null);
    } catch (e) {
      if (kDebugMode) debugPrint('[SemesterProgress] Offline write queued: $e');
      _updateProgressCache(userId, semesterCode, data);
      
      await _cache.enqueueMutation(userId, {
        'action': 'save_course_marks',
        'semesterCode': semesterCode,
        'data': data,
      });
    }
  }
  
  void _updateProgressCache(String userId, String semesterCode, Map<String, dynamic> data) {
    final cacheKey = 'marks_${userId}_$semesterCode';
    final cached = _cache.getMapData('semester_progress_box', cacheKey) ?? {'data': []};
    final list = List<Map<String, dynamic>>.from(cached['data'] ?? []);
    
    final normalizedCode = (data['course_code'] as String).toUpperCase().replaceAll(' ', '');
    final index = list.indexWhere((m) => (m['course_code'] as String).toUpperCase().replaceAll(' ', '') == normalizedCode);
    if (index != -1) {
      list[index] = {...list[index], ...data};
    } else {
      // Only add if it's not already there (prevent duplicates)
      list.add(data);
    }
    _cache.setMapData('semester_progress_box', cacheKey, {'data': list});
  }
}

final semesterProgressDataProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, semesterCode) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  return ref.watch(semesterProgressRepositoryProvider).getSemesterProgressData(user.id, semesterCode);
});
