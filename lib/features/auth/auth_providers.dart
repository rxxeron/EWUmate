import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/profile.dart';
import '../../core/services/cache_service.dart';
import '../../core/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileProvider = FutureProvider<Profile?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final user = authRepo.currentUser;

  if (user == null) {
    return null;
  }
  
  try {
    final profile = await authRepo.getProfile(user.id);
    
    if (profile == null) {
      // GHOST SESSION CHECK:
      // If user is authenticated but has no profile, it's likely they were deleted 
      // from the database. We force a sign-out to clear the local session.
      if (kDebugMode) print("DEBUG: Profile not found for ${user.id}. Invalidating session.");
      await authRepo.signOut();
      return null;
    }

    // Fire-and-forget caching
    ref.read(cacheServiceProvider).cacheProfile(user.id, profile.toJson());
    return profile;
  } catch (e) {
    if (kDebugMode) print("DEBUG: Profile network fetch failed, attempting cache: $e");
    final cacheMap = ref.read(cacheServiceProvider).getCachedProfile(user.id);
    if (cacheMap != null) {
      if (kDebugMode) print("DEBUG: Loaded profile from local cache.");
      return Profile.fromJson(cacheMap);
    }
    throw Exception("You are offline. Please connect to the internet to load your profile initially.");
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
    final track = profile?.track ?? 'tri_semester';
    final activeSemRes = await client
        .from('active_semester')
        .select()
        .eq('track', track)
        .limit(1)
        .maybeSingle()
        .timeout(const Duration(seconds: 5));
    
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
        .timeout(const Duration(seconds: 5));

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
            .timeout(const Duration(seconds: 5));

        return currentUnsubmittedRes.isNotEmpty;
      }
    }

    return false;
  } catch (e) {
    if (kDebugMode) print("DEBUG: Grade entry check failed: $e");
    return false;
  }
});
