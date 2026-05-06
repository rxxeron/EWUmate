import 'package:ewumate/core/providers/academic_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ewumate/core/models/semester_analytics.dart';
import 'package:ewumate/core/models/user_semester_state.dart';
import 'package:ewumate/core/providers/supabase_provider.dart';
import 'package:ewumate/core/repositories/auth_repository.dart';
import 'package:ewumate/core/services/cache_service.dart';
import 'package:ewumate/core/utils/course_utils.dart';

part 'dashboard_repository.g.dart';

class DashboardRepository {
  final SupabaseClient _supabase;
  final CacheService _cache;

  DashboardRepository(this._supabase, this._cache);

  Future<SemesterAnalytics?> getAnalytics(
    String userId,
    String semesterCode,
  ) async {
    final safeSem = CourseUtils.cleanSemester(semesterCode);
    final cached = _cache.getCachedDashboardAnalytics(userId, safeSem);
    if (cached != null) {
      _fetchAndCacheAnalytics(userId, safeSem);
      return SemesterAnalytics.fromJson(cached);
    }
    return await _fetchAndCacheAnalytics(userId, safeSem);
  }

  Future<SemesterAnalytics?> _fetchAndCacheAnalytics(
    String userId,
    String semesterCode,
  ) async {
    try {
      final data = await _supabase
          .from('semester_analytics')
          .select()
          .eq('user_id', userId)
          .eq('semester_code', semesterCode)
          .maybeSingle();

      if (data == null) return null;
      final safeSem = CourseUtils.cleanSemester(semesterCode);
      await _cache.cacheDashboardAnalytics(userId, safeSem, data);
      return SemesterAnalytics.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch analytics: $e');
    }
  }

  Future<UserSemesterState?> getUserSemesterState(
    String userId,
    String semesterCode,
  ) async {
    final safeSem = CourseUtils.cleanSemester(semesterCode);
    final cached = _cache.getCachedDashboardSchedule(userId, safeSem);
    if (cached != null) {
      _fetchAndCacheState(userId, safeSem);
      return UserSemesterState.fromJson(cached);
    }
    return await _fetchAndCacheState(userId, safeSem);
  }

  Future<UserSemesterState?> _fetchAndCacheState(
    String userId,
    String semesterCode,
  ) async {
    try {
      final data = await _supabase
          .from('user_semester_states')
          .select()
          .eq('user_id', userId)
          .eq('semester_code', semesterCode)
          .maybeSingle();

      if (data == null) return null;
      final safeSem = CourseUtils.cleanSemester(semesterCode);
      await _cache.cacheDashboardSchedule(userId, safeSem, data);
      return UserSemesterState.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch cache: $e');
    }
  }

  Future<void> updateAnalytics(SemesterAnalytics analytics) async {
    try {
      final json = analytics.toJson();
      await _supabase
          .from('semester_analytics')
          .update(json)
          .eq('id', analytics.id);
      
      // Update cache
      await _cache.cacheDashboardAnalytics(analytics.userId, analytics.semesterCode, json);
    } catch (e) {
      throw Exception('Failed to update analytics: $e');
    }
  }
}

@riverpod
DashboardRepository dashboardRepository(DashboardRepositoryRef ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final cache = ref.watch(cacheServiceProvider);
  return DashboardRepository(supabase, cache);
}

// Quick provider to get dashboard state for current user.
// Assuming semester code is 'Spring2026' for testing purposes, but this should be fetched from active_semester later.
@riverpod
Future<SemesterAnalytics?> currentAnalytics(CurrentAnalyticsRef ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final semCode = ref.watch(currentSemesterCodeProvider).value ?? 'Spring2026';
  final safeSem = CourseUtils.cleanSemester(semCode);
  return repo.getAnalytics(user.id, safeSem);
}

@riverpod
Future<UserSemesterState?> currentSemesterState(
  CurrentSemesterStateRef ref,
) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final semCode = ref.watch(currentSemesterCodeProvider).value ?? 'Spring2026';
  final safeSem = CourseUtils.cleanSemester(semCode);
  return repo.getUserSemesterState(user.id, safeSem);
}
