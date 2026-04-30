import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

/// The Session Guardian monitors the Supabase auth state and 
/// ensures that the session is refreshed properly and persistent.
import '../repositories/profile_repository.dart';

/// The Session Guardian monitors the Supabase auth state and 
/// ensures that the session is refreshed properly and persistent.
final sessionGuardianProvider = Provider<SessionGuardian>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);
  return SessionGuardian(supabase, profileRepo);
});

class SessionGuardian {
  final SupabaseClient _client;
  final ProfileRepository _profileRepo;
  StreamSubscription<AuthState>? _subscription;

  SessionGuardian(this._client, this._profileRepo) {
    _init();
  }

  void _init() {
    _subscription = _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (kDebugMode) {
        print('[SessionGuardian] Auth Event: ${event.name}');
      }

      if (session?.user != null) {
        // Record activity whenever we have a valid session event
        if (event == AuthChangeEvent.signedIn || 
            event == AuthChangeEvent.initialSession ||
            event == AuthChangeEvent.tokenRefreshed) {
          _profileRepo.recordActivity(session!.user.id);
        }
      }

      switch (event) {
        case AuthChangeEvent.signedIn:
          if (kDebugMode) print('[SessionGuardian] User signed in. Session secured.');
          break;
        case AuthChangeEvent.tokenRefreshed:
          if (kDebugMode) print('[SessionGuardian] Token refreshed successfully.');
          break;
        case AuthChangeEvent.signedOut:
          if (kDebugMode) print('[SessionGuardian] User signed out.');
          break;
        case AuthChangeEvent.userUpdated:
          if (kDebugMode) print('[SessionGuardian] Profile/User data updated.');
          break;
        default:
          break;
      }
    });
  }

  /// Proactively refresh the session if needed
  Future<void> refreshNow() async {
    try {
      await _client.auth.refreshSession();
      if (kDebugMode) print('[SessionGuardian] Manual refresh triggered.');
    } catch (e) {
      if (kDebugMode) print('[SessionGuardian] Manual refresh failed: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
