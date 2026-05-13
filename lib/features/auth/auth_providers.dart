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
    final profile = await authRepo.getProfile(user.id).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception("Connection timeout while fetching profile."),
    );
    
    if (profile == null) {
      if (kDebugMode) print("DEBUG: Profile not found for ${user.id}. Onboarding required.");
      return null;
    }

    // Update cache
    ref.read(cacheServiceProvider).cacheProfile(user.id, profile.toJson());
    return profile;
  } catch (e) {
    if (kDebugMode) debugPrint("DEBUG: Profile fetch error (trying cache): $e");
    
    // OFFLINE FALLBACK: Try to load from cache
    final cachedData = ref.read(cacheServiceProvider).getCachedProfile(user.id);
    if (cachedData != null) {
      if (kDebugMode) debugPrint("DEBUG: Successfully loaded profile from cache for offline usage.");
      return Profile.fromJson(cachedData);
    }
    
    // If no cache and network fails, then we really have an error
    rethrow;
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
