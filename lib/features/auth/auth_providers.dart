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

final requiresGradeEntryProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return false;

  final client = Supabase.instance.client;

  try {
    final profile = await ref.watch(profileProvider.future);
    
    // SAFETY: If no profile exists, they are a new user and can't have hanging grades.
    // Skip the database scans entirely.
    if (profile == null) return false;

    // NORMALIZE: Map 'tri' -> 'tri_semester' to match DB Enum constraints
    String track = profile.track ?? profile.semesterType;
    if (track == 'tri') track = 'tri_semester';
    if (track == 'bi') track = 'bi_semester';

    final activeSemRes = await client
        .from('active_semester')
        .select()
        .eq('track', track)
        .limit(1)
        .maybeSingle()
        .timeout(const Duration(seconds: 15))
        .catchError((e) => null);
    
    if (activeSemRes == null) return false;

    final activeCode = activeSemRes['current_semester_code'];

    // PHASE 1: Check for PAST "Hanging" Courses
    // If a course from a previous semester is still 'enrolled' without a grade, 
    // we block immediately regardless of the current semester's dates.
    final pastHangingRes = await client
        .from('enrollments')
        .select('id')
        .eq('user_id', user.id)
        .eq('status', 'enrolled')
        .neq('semester_code', activeCode) // Different from the current active one
        .isFilter('grade', null)
        .limit(1)
        .timeout(const Duration(seconds: 15))
        .catchError((e) => []);

    if (pastHangingRes.isNotEmpty) {
      return true;
    }

    // PHASE 2: Check for CURRENT Semester Hand-off
    // We only block for the current semester if the submission window has started.
    final submissionStartStr = activeSemRes['grade_submission_start'];
    if (submissionStartStr != null) {
      final submissionStart = DateTime.tryParse(submissionStartStr.toString());
      if (submissionStart != null && DateTime.now().isAfter(submissionStart.add(const Duration(days: 1)))) {
        final currentUnsubmittedRes = await client
            .from('enrollments')
            .select('id')
            .eq('user_id', user.id)
            .eq('status', 'enrolled')
            .eq('semester_code', activeCode) // Specifically the current one
            .isFilter('grade', null)
            .limit(1)
            .timeout(const Duration(seconds: 15))
            .catchError((e) => []);

        return currentUnsubmittedRes.isNotEmpty;
      }
    }

    return false;
  } catch (e) {
    if (kDebugMode) print("DEBUG: Grade entry check failed: $e");
    return false;
  }
});
