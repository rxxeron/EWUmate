import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

/// The Session Guardian monitors the Supabase auth state and 
/// ensures that the session is refreshed properly and persistent.
final sessionGuardianProvider = Provider<SessionGuardian>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SessionGuardian(supabase);
});

class SessionGuardian {
  final SupabaseClient _client;
  StreamSubscription<AuthState>? _subscription;

  SessionGuardian(this._client) {
    _init();
  }

  void _init() {
    _subscription = _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (kDebugMode) {
        print('[SessionGuardian] Auth Event: ${event.name}');
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
