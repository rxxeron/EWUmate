import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/widgets/sky_animation.dart';
import 'auth_providers.dart';
import '../../core/repositories/auth_repository.dart' hide authStateProvider;
import '../../core/services/cache_service.dart';

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

                // 0. Primary Auth Check: If the Supabase session is null, they are signed out
                final hasSession = Supabase.instance.client.auth.currentSession != null;
                if (user == null && !hasSession) {
                  debugPrint("[CheckAuth] User is signed out. Redirecting to Login.");
                  WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
                  return const CircularProgressBinding(text: 'Redirecting to login...');
                }

                // 1. If we have NO profile data
                if (profile == null) {
                  debugPrint("[CheckAuth] Profile is NULL. User is: ${user?.id}");
                  
                  if (user != null) {
                    // SAFETY: Wait for the profile provider to finish its first fetch after login.
                    // If it's still null after being authenticated, then we can assume it's a new user.
                    if (profileAsync.isLoading || profileAsync.isRefreshing) {
                       return const CircularProgressBinding(text: 'Loading identity...');
                    }
                    
                    // Logged in but no record in DB yet
                    debugPrint("[CheckAuth] Redirecting to Onboarding (No Profile Record)");
                    WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/onboarding/program'));
                    return const CircularProgressBinding(text: 'Setting up your profile...');
                  }

                  // Not logged in -> Login
                  // Truly no identity found? Wait briefly for Supabase to be 100% sure.
                  // We also check if we have a cached identity - if so, we shouldn't kick them out yet.
                  Future.delayed(const Duration(seconds: 10), () {
                    final hasLastUser = ref.read(cacheServiceProvider).getLastUserId() != null;
                    if (mounted && user == null && Supabase.instance.client.auth.currentUser == null && !hasLastUser) {
                      debugPrint("[CheckAuth] No current user and no cached identity. Redirecting to login.");
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

class _ErrorView extends ConsumerWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade900,
              minimumSize: const Size(200, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Local Cache?'),
                  content: const Text('This will wipe all offline data and restart the app. Use this if you are seeing stale information.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), 
                      child: const Text('Clear', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(cacheServiceProvider).clearAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared. Restarting...')),
                  );
                  onRetry();
                }
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              minimumSize: const Size(200, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Clear Cache'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout?'),
                  content: const Text('Are you sure you want to log out and try again?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), 
                      child: const Text('Logout', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('Logout and Reset'),
          ),
        ],
      ),
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
