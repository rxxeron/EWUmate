import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../providers/supabase_provider.dart';
import '../services/cache_service.dart';

part 'profile_repository.g.dart';

class ProfileRepository {
  final SupabaseClient _supabase;
  final CacheService _cache;

  ProfileRepository(this._supabase, this._cache);

  Future<Profile?> getProfile(String userId) async {
    // 1. Try cache first
    final cached = _cache.getCachedProfile(userId);
    if (cached != null) {
      // Don't wait, immediately fetch offline then refresh background
      _fetchAndCache(userId);
      return Profile.fromJson(cached);
    }

    // 2. Fallback to network
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
      await _supabase.from('profiles').upsert(profile.toJson());
      await _cache.cacheProfile(profile.id, profile.toJson());
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

        await Future.wait([
          _supabase.from('profiles').update({'enrolled_sections': updatedSections}).eq('id', userId),
          _supabase.from('enrollments').insert({
            'user_id': userId,
            'course_code': courseCode,
            'semester_code': semesterCode,
            'section_id': sectionId,
            'section': sectionNumber,
          })
        ]);
      await _fetchAndCache(userId);
    } catch (e) {
      throw Exception('Failed to enroll course: $e');
    }
  }

  Future<void> dropCourseSection({
    required String userId,
    required String sectionId,
    required List<String> currentSections,
  }) async {
    try {
      final updatedSections = List<String>.from(currentSections)..remove(sectionId);
      
      await Future.wait([
        _supabase.from('profiles').update({'enrolled_sections': updatedSections}).eq('id', userId),
        _supabase.from('enrollments').delete().eq('user_id', userId).eq('section_id', sectionId),
      ]);
      
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

        await Future.wait([
          _supabase.from('profiles').update({'enrolled_sections': updatedSections}).eq('id', userId),
          _supabase.from('enrollments').delete().eq('user_id', userId).eq('section_id', oldSectionId),
          _supabase.from('enrollments').insert({
            'user_id': userId,
            'course_code': courseCode,
            'semester_code': semesterCode,
            'section_id': newSectionId,
            'section': newSectionNumber,
          })
        ]);
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
      // Offline
    }
  }
}

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final cache = ref.watch(cacheServiceProvider);
  return ProfileRepository(supabase, cache);
}

@riverpod
Stream<Profile?> userProfile(UserProfileRef ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value(null);
  
  return ref.watch(profileRepositoryProvider).streamProfile(user.id);
}
