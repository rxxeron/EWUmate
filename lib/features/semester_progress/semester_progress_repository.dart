import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/cache_service.dart';
import '../../core/repositories/auth_repository.dart';

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
      final enrollments = await _supabase
          .from('enrollments')
          .select('course_code')
          .eq('user_id', userId)
          .eq('semester_code', semesterCode);

      final enrolledCourseCodes = (enrollments as List).map((e) => e['course_code'] as String).toList();

      if (enrolledCourseCodes.isEmpty) return [];

      final marksRes = await _supabase
          .from('semester_course_marks')
          .select('*')
          .eq('user_id', userId)
          .eq('semester_code', semesterCode)
          .inFilter('course_code', enrolledCourseCodes);
      
      final marksData = List<Map<String, dynamic>>.from(marksRes);

      List<Map<String, dynamic>> progressData = [];
      for (var code in enrolledCourseCodes) {
        final existingMark = marksData.firstWhere(
          (m) => m['course_code'] == code, 
          orElse: () => <String, dynamic>{
            'id': 'new_$code', 
            'user_id': userId,
            'semester_code': semesterCode,
            'course_code': code,
            'is_new': true,
          }
        );
        progressData.add(existingMark);
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

      final res = await _supabase.from('semester_course_marks')
          .upsert(
            data, 
            onConflict: 'user_id,semester_code,course_code'
          )
          .select()
          .single();
      
      _updateProgressCache(userId, semesterCode, res);
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
    
    final index = list.indexWhere((m) => m['course_code'] == data['course_code']);
    if (index != -1) {
      // Merge new data with existing to preserve fields like 'id' if 'data' is partial
      list[index] = {...list[index], ...data};
    } else {
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
