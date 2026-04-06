import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/cache_service.dart';

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
      _cache.setMapData('dashboard_box', 'active_semester_code', {'code': code});
      return code;
    } catch(e) {
      final cached = _cache.getMapData('dashboard_box', 'active_semester_code');
      return cached?['code'] ?? 'Spring2026';
    }
  }

  Future<List<Map<String, dynamic>>> getSemesterProgressData(String userId, String semesterCode) async {
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
          orElse: () => {
            'course_code': code,
            'is_new': true,
          }
        );
        progressData.add(existingMark);
      }
      
      _cache.setMapData('dashboard_box', 'progress_${userId}_$semesterCode', {'data': progressData});
      return progressData;
      
    } catch (e) {
      if (kDebugMode) debugPrint('[SemesterProgress] Offline read fallback');
      final cached = _cache.getMapData('dashboard_box', 'progress_${userId}_$semesterCode');
      if (cached != null && cached['data'] != null) {
        return List<Map<String, dynamic>>.from(cached['data']);
      }
      return [];
    }
  }

  Future<void> saveCourseMarks(String userId, String semesterCode, Map<String, dynamic> data) async {
    final isNew = data['is_new'] == true;
    data.remove('is_new');

    data['user_id'] = userId;
    data['semester_code'] = semesterCode;
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();

    try {
      if (isNew) {
        await _supabase.from('semester_course_marks').insert(data);
      } else {
        await _supabase.from('semester_course_marks')
            .update(data)
            .eq('user_id', userId)
            .eq('semester_code', semesterCode)
            .eq('course_code', data['course_code']);
      }
      _updateProgressCache(userId, semesterCode, data);
    } catch (e) {
      if (kDebugMode) debugPrint('[SemesterProgress] Offline write queued');
      _updateProgressCache(userId, semesterCode, data);
      
      data['is_new'] = isNew; // restore for queue
      await _cache.enqueueMutation(userId, {
        'action': 'save_course_marks',
        'semesterCode': semesterCode,
        'data': data,
      });
    }
  }
  
  void _updateProgressCache(String userId, String semesterCode, Map<String, dynamic> data) {
    final cached = _cache.getMapData('dashboard_box', 'progress_${userId}_$semesterCode') ?? {'data': []};
    final list = List<dynamic>.from(cached['data'] ?? []);
    final index = list.indexWhere((m) => (m as Map)['course_code'] == data['course_code']);
    if (index != -1) {
      list[index] = data;
    } else {
      list.add(data);
    }
    _cache.setMapData('dashboard_box', 'progress_${userId}_$semesterCode', {'data': list});
  }
}
