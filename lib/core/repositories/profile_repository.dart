import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../providers/supabase_provider.dart';
import '../services/cache_service.dart';
import 'package:ewumate/features/dashboard/dashboard_repository.dart';

part 'profile_repository.g.dart';

class ProfileRepository {
  final SupabaseClient _supabase;
  final CacheService _cache;
  final DashboardRepository _dashboardRepo;

  ProfileRepository(this._supabase, this._cache, this._dashboardRepo);

  Future<Profile?> getProfile(String userId, {bool forceRefresh = true}) async {
    if (!forceRefresh) {
      final cached = _cache.getCachedProfile(userId);
      if (cached != null) {
        _fetchAndCache(userId);
        return Profile.fromJson(cached);
      }
    }

    return await _fetchAndCache(userId);
  }

  Future<Profile?> _fetchAndCache(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;

      // Update Cache
      await _cache.cacheProfile(userId, data);

      return Profile.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  Future<void> updateProfile(Profile profile) async {
    try {
      // 1. Sanitize Name (Capitalize each word + trim)
      final sanitizedName = profile.fullName?.trim().split(' ')
          .map((word) => word.isNotEmpty 
              ? word[0].toUpperCase() + word.substring(1).toLowerCase() 
              : '')
          .join(' ') ?? '';
      
      final sanitizedProfile = profile.copyWith(fullName: sanitizedName);

      await _supabase.from('profiles').upsert(sanitizedProfile.toJson());
      await _cache.cacheProfile(sanitizedProfile.id, sanitizedProfile.toJson());
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> enrollCourseSection({
    required String userId,
    required String courseCode,
    required String semesterCode,
    required String sectionId,
      required String sectionNumber,
      required List<String> currentSections,
    }) async {
      try {
        // 1. Update Profile Array
        final updatedSections = List<String>.from(currentSections)..add(sectionId);

        // 1. Update Profile enrolled_sections sequentially
        await _supabase
            .from('profiles')
            .update({'enrolled_sections': updatedSections})
            .eq('id', userId);

        // 2. Insert the enrollment record
        await _supabase.from('enrollments').insert({
          'user_id': userId,
          'course_code': courseCode,
          'semester_code': semesterCode,
          'section_id': sectionId,
          'section': sectionNumber,
          'status': 'enrolled',
        });
        
        // 3. Force Reset Database Weekly Schedule cache (Trigger re-sync)
        await _supabase
            .from('user_semester_states')
            .upsert({
              'user_id': userId,
              'semester_code': semesterCode,
              'weekly_grid_cache': null,
            }, onConflict: 'user_id,semester_code');

        // 4. Proactive Sync Trigger (Rebuilds dashboard schedule immediately)
        await _dashboardRepo.syncWeeklySchedule(userId);

        // 4. Clear local Hive enrollment caches
        _cache.clearEnrollmentCache(userId, semesterCode);

      await _fetchAndCache(userId);
    } catch (e) {
      throw Exception('Failed to enroll course: $e');
    }
  }

  Future<void> dropCourseSection({
    required String userId,
    required String sectionId,
    required String semesterCode,
    required List<String> currentSections,
  }) async {
    try {
      final updatedSections = List<String>.from(currentSections)..remove(sectionId);
      
      // 1. Update Profile enrolled_sections sequentially
      await _supabase
          .from('profiles')
          .update({'enrolled_sections': updatedSections})
          .eq('id', userId);

      // 2. Delete the enrollment record
      await _supabase
          .from('enrollments')
          .delete()
          .eq('user_id', userId)
          .eq('section_id', sectionId);
      
      // 3. Force Reset Database Weekly Schedule cache
      await _supabase
          .from('user_semester_states')
          .upsert({
            'user_id': userId,
            'semester_code': semesterCode,
            'weekly_grid_cache': null,
          }, onConflict: 'user_id,semester_code');

      // 4. Proactive Sync Trigger (Ensures schedule is correct after drop)
      await _dashboardRepo.syncWeeklySchedule(userId);

      // 4. Clear local Hive caches
      _cache.clearEnrollmentCache(userId, semesterCode);
      _cache.clearSemesterProgressCache(userId, semesterCode);

      // 4. Force refresh local profile cache
      await _fetchAndCache(userId);
    } catch (e) {
      throw Exception('Failed to drop course: $e');
    }
  }

  Future<void> switchCourseSection({
    required String userId,
    required String courseCode,
    required String semesterCode,
    required String oldSectionId,
    required String newSectionId,
      required String newSectionNumber,
      required List<String> currentSections,
    }) async {
      try {
        final updatedSections = List<String>.from(currentSections)
          ..remove(oldSectionId)
          ..add(newSectionId);

        // 1. Update Profile enrolled_sections
        await _supabase
            .from('profiles')
            .update({'enrolled_sections': updatedSections})
            .eq('id', userId);

        // 2. Atomic Upsert: Update if exists, otherwise Insert
        // This is much safer than delete+insert as it handles conflicts natively
        await _supabase
            .from('enrollments')
            .upsert({
              'user_id': userId,
              'course_code': courseCode,
              'semester_code': semesterCode,
              'section_id': newSectionId,
              'section': newSectionNumber,
              'status': 'enrolled', // Ensure it's marked as enrolled
            }, onConflict: 'user_id,semester_code,course_code');

        // 3. Force Reset Database Weekly Schedule cache
        await _supabase
            .from('user_semester_states')
            .upsert({
              'user_id': userId,
              'semester_code': semesterCode,
              'weekly_grid_cache': null,
            }, onConflict: 'user_id,semester_code');

        // 4. Proactive Sync Trigger (Ensures new section timing is reflected)
        await _dashboardRepo.syncWeeklySchedule(userId);

        // 4. Clear local Hive caches
        _cache.clearEnrollmentCache(userId, semesterCode);

      await _fetchAndCache(userId);
    } catch (e) {
      throw Exception('Failed to switch section: $e');
    }
  }

  Stream<Profile?> streamProfile(String userId) async* {
    final cached = _cache.getCachedProfile(userId);
    if (cached != null) {
      yield Profile.fromJson(cached);
    }
    
    // Background refresh immediately to break any stale caches
    _fetchAndCache(userId).then((fresh) {
      if (fresh != null && !kIsWeb) {
        // This will naturally trigger the stream below if realtime is active,
        // but we yield it anyway just in case.
      }
    });

    try {
      await for (final event in _supabase
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', userId)) {
        if (event.isNotEmpty) {
          final data = event.first;
          _cache.cacheProfile(userId, data);
          yield Profile.fromJson(data);
        }
      }
    } catch (e) {
      // Offline fallback already handled by initial yield
    }
  }

  Future<void> recordActivity(String userId) async {
    try {
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 2. Increment app_open_count and update last_active_at + app_version
      await _supabase.rpc('increment_app_open_count', params: {
        'p_user_id': userId,
      });
      
      // Update app_version separately or via RPC if supported
      await _supabase.from('profiles').update({
        'app_version': currentVersion,
        'last_active_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      
    } catch (e) {
      if (kDebugMode) print('Failed to record activity: $e');
    }
  }
}

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final cache = ref.watch(cacheServiceProvider);
  final dashboardRepo = ref.watch(dashboardRepositoryProvider);
  return ProfileRepository(supabase, cache, dashboardRepo);
}

@Riverpod(keepAlive: true)
Stream<Profile?> userProfile(UserProfileRef ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value(null);
  
  return ref.watch(profileRepositoryProvider).streamProfile(user.id);
}
