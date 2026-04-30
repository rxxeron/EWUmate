import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  
  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password, String fullName) async {
    final response = await _client.auth.signUp(
      email: email, 
      password: password,
      data: {'full_name': fullName},
    );
    // Profile is created via Postgres Trigger
  }

  Future<void> signOut() async {
    try {
      // Clear local Hive cache before signing out from Supabase
      await _client.auth.signOut();
    } catch (e) {
      if (kDebugMode) (){}();
    }
  }

  Future<Profile?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .limit(1)
          .timeout(const Duration(seconds: 5));

      if (response.isEmpty) return null;
      return Profile.fromJson(response.first);
    } catch (e) {
      if (kDebugMode) (){}();
      // Throwing instead of returning null so FutureProvider enters 'error' state
      throw Exception("Connection timed out. Please check your internet.");
    }
  }
}
