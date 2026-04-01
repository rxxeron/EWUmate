import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/profile.dart';
import 'auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileProvider = FutureProvider<Profile?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final user = authRepo.currentUser;

  if (user == null) {
    return null;
  }
  
  final profile = await authRepo.getProfile(user.id);
  return profile;
});

final authStateProvider = StreamProvider<AuthState>((ref) async* {
  final client = Supabase.instance.client;
  
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

    final submissionStartStr = activeSemRes['grade_submission_start'];
    if (submissionStartStr == null) return false;
    final submissionStart = DateTime.tryParse(submissionStartStr.toString());
    if (submissionStart == null || DateTime.now().isBefore(submissionStart.add(const Duration(days: 1)))) {
      return false;
    }

    final unsubmittedGradesRes = await client
        .from('enrollments')
        .select('id')
        .eq('user_id', user.id)
        .eq('status', 'enrolled')
        .isFilter('grade', null)
        .limit(1)
        .timeout(const Duration(seconds: 5));

    return unsubmittedGradesRes.isNotEmpty;
  } catch (e) {
    return false;
  }
});
