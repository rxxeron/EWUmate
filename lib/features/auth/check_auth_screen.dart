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
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    _startStallTimer();
  }

  void _startStallTimer() {
    setState(() => _showRetry = false);
    _stallTimer?.cancel();
    _stallTimer = Timer(const Duration(seconds: 45), () {
      if (mounted) {
        debugPrint("[CheckAuth] STALL DETECTED: Screen stuck for 45s. Showing retry option.");
        setState(() => _showRetry = true);
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
    final profileAsync = ref.watch(profileProvider);
    final user = ref.watch(currentUserProvider); // Reactive user source

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SkyAnimationWidget()),
          Center(
            child: profileAsync.when(
              data: (profile) {
                _stallTimer?.cancel();

                // 1. If we have NO profile data
                if (profile == null) {
                  debugPrint("[CheckAuth] Profile is NULL. User is: ${user?.id}");
                  
                  if (user != null) {
                    // Logged in but no record in DB yet
                    debugPrint("[CheckAuth] Redirecting to Onboarding (No Profile Record)");
                    WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/onboarding/program'));
                    return const CircularProgressBinding(text: 'Setting up your profile...');
                  }

                  // Not logged in -> Login
                  debugPrint("[CheckAuth] Waiting for identity...");
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted && user == null && Supabase.instance.client.auth.currentUser == null) {
                      debugPrint("[CheckAuth] Still no user after 3s. Redirecting to Login.");
                      context.go('/login');
                    }
                  });
                  return const CircularProgressBinding(text: 'Searching for you...');
                }

                // 2. We HAVE profile data
                debugPrint("[CheckAuth] Profile Found: ${profile.id}, Status: ${profile.onboardingStatus}, Program: ${profile.programCode}");

                if (profile.onboardingStatus == 'pending' ||
                    profile.onboardingStatus == 'registered' ||
                    profile.programCode == null) {
                  debugPrint("[CheckAuth] Redirecting to Onboarding Flow (Incomplete Profile)");
                  WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/onboarding/program'));
                } else if (profile.onboardingStatus == 'course_history') {
                  debugPrint("[CheckAuth] Redirecting to Course History (Partial Completion)");
                  WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/onboarding/course-history'));
                } else {
                  debugPrint("[CheckAuth] Onboarding Complete. Checking Grade Blocker.");
                  return const _GradeBlockerWrapper();
                }
                return const CircularProgressBinding(text: 'Restoring session...');
              },
              error: (err, stack) {
                debugPrint("[CheckAuth] ERROR: $err\n$stack");
                _stallTimer?.cancel();
                return _ErrorView(
                  message: 'Connection issue: $err',
                  onRetry: () {
                    _startStallTimer();
                    ref.refresh(profileProvider);
                  },
                );
              },
              loading: () {
                debugPrint("[CheckAuth] Loading state...");
                return const CircularProgressBinding(text: 'Securing universe...');
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Removed _ProfileCheckWrapper as its logic is now integrated into CheckAuthScreen for Zero-Wait Entry

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
