import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/profile.dart';
import '../../core/services/cache_service.dart';
import '../../core/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileProvider = StreamProvider<Profile?>((ref) async* {
  final authRepo = ref.watch(authRepositoryProvider);
  final user = authRepo.currentUser;
  final cacheService = ref.read(cacheServiceProvider);

  String? effectiveUserId = user?.id;
  if (effectiveUserId == null) {
    effectiveUserId = cacheService.getLastUserId();
    if (effectiveUserId == null) {
      yield null;
      return;
    }
  }
  
  final userId = effectiveUserId;

  // 1. Yield Cache Immediately (Frame 1)
  final cachedData = cacheService.getCachedProfile(userId);
  if (cachedData != null) {
    debugPrint("[ProfileProvider] Serving Cache instantly on Frame 1...");
    yield Profile.fromJson(cachedData);
  }

  // 2. Background retry loop for online updates
  while (true) {
    try {
      debugPrint("[ProfileProvider] Attempting Online Fetch for: $userId");
      final profile = await authRepo.getProfile(userId).timeout(
        const Duration(seconds: 10),
      );
      
      if (profile != null) {
        cacheService.cacheProfile(userId, profile.toJson());
        yield profile;
        break; 
      }
    } catch (e) {
      debugPrint("[ProfileProvider] Online failed: $e");
      
      // Retry every 5 seconds until success
      await Future.delayed(const Duration(seconds: 5));
    }
  }
});

final authStateProvider = StreamProvider<AuthState>((ref) async* {
  final client = Supabase.instance.client;
  // Tracing log removed for release
  
  // 1. Emit the current session immediately
  final initialSession = client.auth.currentSession;
  yield AuthState(AuthChangeEvent.initialSession, initialSession);

  // 2. Then pipe all future auth changes
  yield* client.auth.onAuthStateChange;
});

final requiresGradeEntryProvider = StreamProvider<bool>((ref) async* {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) {
    yield false;
    return;
  }

  final cacheService = ref.read(cacheServiceProvider);
  final client = Supabase.instance.client;

  // 1. Emit cached decision instantly (Frame 1)
  final cached = cacheService.getMapData('profile_box', '${user.id}_requires_grade_entry');
  if (cached != null) {
    yield cached['requires'] as bool? ?? false;
  } else {
    yield false;
  }

  // 2. Fetch fresh decision online
  try {
    final profile = await ref.watch(profileProvider.future);
    if (profile == null) {
      yield false;
      return;
    }

    // NORMALIZE: Map 'tri' -> 'tri_semester' to match DB Enum constraints
    String track = profile.track ?? profile.semesterType;
    if (track == 'tri') track = 'tri_semester';
    if (track == 'bi') track = 'bi_semester';

    // Fetch active semester and unsubmitted enrollments concurrently
    final results = await Future.wait([
      client.from('active_semester')
          .select()
          .eq('track', track)
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 10)),
      client.from('enrollments')
          .select('id, semester_code, grade')
          .eq('user_id', user.id)
          .eq('status', 'enrolled')
          .isFilter('grade', null)
          .timeout(const Duration(seconds: 10))
          .catchError((e) => <Map<String, dynamic>>[]),
    ]);

    final activeSemRes = results[0] as Map<String, dynamic>?;
    final unsubmittedEnrollments = List<Map<String, dynamic>>.from(results[1] as List? ?? []);

    if (activeSemRes == null) {
      yield false;
      return;
    }

    final activeCode = activeSemRes['current_semester_code'];
    bool requiresGrade = false;

    // Check past unsubmitted courses
    final hasPastHanging = unsubmittedEnrollments.any((e) => e['semester_code'] != activeCode);
    if (hasPastHanging) {
      requiresGrade = true;
    } else {
      // Check current semester hand-off
      final submissionStartStr = activeSemRes['grade_submission_start'];
      if (submissionStartStr != null) {
        final submissionStart = DateTime.tryParse(submissionStartStr.toString());
        if (submissionStart != null && DateTime.now().isAfter(submissionStart.add(const Duration(days: 1)))) {
          final hasCurrentUnsubmitted = unsubmittedEnrollments.any((e) => e['semester_code'] == activeCode);
          if (hasCurrentUnsubmitted) {
            requiresGrade = true;
          }
        }
      }
    }

    // Cache the fresh decision
    await cacheService.setMapData('profile_box', '${user.id}_requires_grade_entry', {'requires': requiresGrade});
    yield requiresGrade;
  } catch (e) {
    if (kDebugMode) print("DEBUG: Grade entry check failed: $e");
    // Fall back to cached value, already yielded
  }
});
