import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/widgets/sky_animation.dart';
import 'auth_providers.dart';
import '../../core/repositories/auth_repository.dart' hide authStateProvider;

class CheckAuthScreen extends ConsumerStatefulWidget {
  const CheckAuthScreen({super.key});

  @override
  ConsumerState<CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends ConsumerState<CheckAuthScreen> {
  Timer? _stallTimer;

  @override
  void initState() {
    super.initState();
    _startStallTimer();
  }

  void _startStallTimer() {
    _stallTimer?.cancel();
    _stallTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        debugPrint("[CheckAuth] STALL DETECTED: Screen stuck for 30s. Forcing logout.");
        ref.read(authRepositoryProvider).signOut();
        if (context.mounted) context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _stallTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SkyAnimationWidget()),
          Center(
            child: authState.when(
              data: (state) {
                final syncUser = Supabase.instance.client.auth.currentUser;
                
                // If it's an explicit sign-out event, go to login immediately.
                if (state.event == AuthChangeEvent.signedOut) {
                  _stallTimer?.cancel();
                  WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
                  return const CircularProgressBinding();
                }

                // If no session exists:
                if (state.session == null && syncUser == null) {
                  // If it's the initial event, don't redirect yet! 
                  // Supabase might be refreshing the session in the background.
                  // We wait for the stall timer to handle it if no session appears.
                  if (state.event == AuthChangeEvent.initialSession) {
                    return const CircularProgressBinding(text: 'Securing session...');
                  }
                  
                  // Otherwise, if we're not signed in, go to login.
                  _stallTimer?.cancel();
                  WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
                  return const CircularProgressBinding();
                }

                // Valid session exists, proceed.
                return const _ProfileCheckWrapper();
              },
              error: (err, stack) {
                _stallTimer?.cancel();
                return _ErrorView(
                  message: 'Auth Error: $err',
                  onRetry: () {
                    _startStallTimer();
                    ref.refresh(authStateProvider);
                  },
                );
              },
              loading: () => const CircularProgressBinding(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCheckWrapper extends ConsumerWidget {
  const _ProfileCheckWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    debugPrint("[CheckAuth] Phase: Profile Verification (${profileAsync.isLoading ? 'WAITING' : 'READY'})");

    return profileAsync.when(
      data: (profile) {
        if (profile == null ||
            profile.onboardingStatus == 'pending' ||
            profile.onboardingStatus == 'registered' ||
            profile.programCode == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/onboarding/program');
          });
          return const CircularProgressBinding(text: 'Initializing experience...');
        } else if (profile.onboardingStatus == 'course_history') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/onboarding/course-history');
          });
          return const CircularProgressBinding(text: 'Loading Course History...');
        } else {
          return const _GradeBlockerWrapper();
        }
      },
      error: (err, stack) {
        if (err.toString().contains("timeout") || err.toString().contains("Profile not found")) {
           // We NO LONGER force sign-out on timeout. 
           // This prevents users from being logged out due to poor network.
        }
        return _ErrorView(
          message: 'Could not fetch profile: $err',
          onRetry: () => ref.refresh(profileProvider),
        );
      },
      loading: () => const CircularProgressBinding(),
    );
  }
}

class _GradeBlockerWrapper extends ConsumerWidget {
  const _GradeBlockerWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradeCheckAsync = ref.watch(requiresGradeEntryProvider);
    debugPrint("[CheckAuth] Phase: Grade Scanning (${gradeCheckAsync.isLoading ? 'SCANNING' : 'DONE'})");

    return gradeCheckAsync.when(
      data: (requiresGrade) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (requiresGrade) {
            context.go('/results/grade-entry');
          } else {
            context.go('/dashboard');
          }
        });
        return const CircularProgressBinding(text: 'Preparing Dashboard...');
      },
      error: (err, stack) => _ErrorView(
        message: 'Semester check failed: $err',
        onRetry: () => ref.refresh(requiresGradeEntryProvider),
      ),
      loading: () => const CircularProgressBinding(),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off, color: Colors.white, size: 64),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue.shade900,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('Try Again'),
        ),
      ],
    );
  }
}

class CircularProgressBinding extends StatelessWidget {
  final String text;
  const CircularProgressBinding({super.key, this.text = 'Syncing Universe...'});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.white),
        const SizedBox(height: 16),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
