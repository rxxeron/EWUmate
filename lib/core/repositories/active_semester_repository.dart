import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';
import '../services/redis_service.dart';
import '../utils/course_utils.dart';

part 'active_semester_repository.g.dart';

class ActiveSemesterRepository {
  final SupabaseClient _supabase;
  final RedisService _redis;
  static final Map<String, (Map<String, dynamic> data, DateTime cachedAt)> _activeSemesterCache = {};
  static List<Map<String, dynamic>>? _allSemestersCache;
  static DateTime? _allSemestersCachedAt;
  static const Duration _ttl = Duration(days: 1);

  ActiveSemesterRepository(this._supabase, this._redis);

  Future<Map<String, dynamic>> getActiveSemester(String track, {bool forceRefresh = false}) async {
    // NORMALIZE: Strict 'bi_semester' or 'tri_semester'
    final normalizedTrack = CourseUtils.normalizeTrack(track);

    // 1. Check L1 Memory Cache
    if (!forceRefresh && _activeSemesterCache.containsKey(normalizedTrack)) {
      final entry = _activeSemesterCache[normalizedTrack]!;
      if (DateTime.now().difference(entry.$2) < _ttl) {
        return entry.$1;
      }
    }

    // 2. Check L2 Upstash Redis Cloud Cache
    if (!forceRefresh) {
      try {
        final redisData = await _redis.getMap('global:active_semester:$normalizedTrack');
        if (redisData != null && redisData.isNotEmpty) {
          _activeSemesterCache[normalizedTrack] = (redisData, DateTime.now());
          return redisData;
        }
      } catch (_) {}
    }

    // 3. Fallback L3 to Supabase Database
    final response = await _supabase
        .from('active_semester')
        .select()
        .eq('track', normalizedTrack)
        .limit(1)
        .single();
    
    _activeSemesterCache[normalizedTrack] = (response, DateTime.now());
    return response;
  }

  Future<List<Map<String, dynamic>>> getAllSemesters({bool forceRefresh = false}) async {
    // 1. Check L1 Memory Cache
    if (!forceRefresh && _allSemestersCache != null && _allSemestersCachedAt != null) {
      if (DateTime.now().difference(_allSemestersCachedAt!) < const Duration(hours: 12)) {
        return _allSemestersCache!;
      }
    }

    // 2. Check L2 Upstash Redis Cloud Cache
    if (!forceRefresh) {
      try {
        final redisList = await _redis.getList('global:semesters');
        if (redisList != null && redisList.isNotEmpty) {
          final list = redisList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _allSemestersCache = list;
          _allSemestersCachedAt = DateTime.now();
          return list;
        }
      } catch (_) {}
    }

    // 3. Fallback L3 to Supabase Database
    final response = await _supabase
        .from('semesters')
        .select('title')
        .order('created_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(response);
    _allSemestersCache = list;
    _allSemestersCachedAt = DateTime.now();
    return list;
  }
}

@riverpod
ActiveSemesterRepository activeSemesterRepository(ActiveSemesterRepositoryRef ref) {
  return ActiveSemesterRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(redisServiceProvider),
  );
}
