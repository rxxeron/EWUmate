import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/widgets/sky_animation.dart';
import '../../core/widgets/animated_startup_cover.dart';
import '../../core/services/tutorial_service.dart';
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
  final DateTime _initTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startStallTimer();
  }

  void _navigateWithDelay(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final elapsed = DateTime.now().difference(_initTime);
      const minDuration = Duration(milliseconds: 3500);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
      if (mounted) {
        context.go(route);
      }
    });
  }

  void _startStallTimer() {
    _stallTimer?.cancel();
    _stallTimer = Timer(const Duration(seconds: 45), () {
      if (mounted) {
        debugPrint("[CheckAuth] STALL DETECTED: Screen stuck for 45s. Showing retry option.");
        setState(() {});
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
                  _navigateWithDelay('/login');
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
                    _navigateWithDelay('/onboarding/program');
                    return const CircularProgressBinding(text: 'Setting up your profile...');
                  }

                  // Not logged in -> Login
                  // Truly no identity found? Wait briefly for Supabase to be 100% sure.
                  // We also check if we have a cached identity - if so, we shouldn't kick them out yet.
                  Future.delayed(const Duration(seconds: 10), () {
                    final hasLastUser = ref.read(cacheServiceProvider).getLastUserId() != null;
                    if (mounted && user == null && Supabase.instance.client.auth.currentUser == null && !hasLastUser) {
                      debugPrint("[CheckAuth] No current user and no cached identity. Redirecting to login.");
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  });
                  return const CircularProgressBinding(text: 'Searching for you...');
                }

                // 2. We HAVE profile data
                debugPrint("[CheckAuth] Profile Found: ${profile.id}, Status: ${profile.onboardingStatus}, Program: ${profile.programCode}");

                if (profile.onboardingStatus == 'pending' ||
                    profile.onboardingStatus == 'registered' ||
                    profile.programCode == null) {
                  debugPrint("[CheckAuth] Redirecting to Profile Setup Flow (Incomplete Profile)");
                  _navigateWithDelay('/onboarding/profile-setup');
                } else if (profile.onboardingStatus == 'course_history') {
                  debugPrint("[CheckAuth] Redirecting to Course History (Partial Completion)");
                  _navigateWithDelay('/onboarding/course-history');
                } else {
                  debugPrint("[CheckAuth] Onboarding Complete. Checking Grade Blocker.");
                  return _GradeBlockerWrapper(onNavigate: _navigateWithDelay);
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
                    ref.invalidate(profileProvider);
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
  final void Function(String route) onNavigate;
  const _GradeBlockerWrapper({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradeCheckAsync = ref.watch(requiresGradeEntryProvider);
    debugPrint("[CheckAuth] Phase: Grade Scanning (${gradeCheckAsync.isLoading ? 'SCANNING' : 'DONE'})");

    return gradeCheckAsync.when(
      data: (requiresGrade) {
        if (requiresGrade) {
          onNavigate('/results/grade-entry');
        } else {
          // Check if welcome tour needs to be shown
          _checkWelcomeTourAndNavigate();
        }
        return const CircularProgressBinding(text: 'Preparing Dashboard...');
      },
      error: (err, stack) => _ErrorView(
        message: 'Semester check failed: $err',
        onRetry: () => ref.refresh(requiresGradeEntryProvider),
      ),
      loading: () => const CircularProgressBinding(),
    );
  }

  Future<void> _checkWelcomeTourAndNavigate() async {
    final hasSeenTour = await TutorialService().hasCompletedWelcomeTour();
    if (!hasSeenTour) {
      onNavigate('/onboarding/welcome-tour');
    } else {
      onNavigate('/dashboard');
    }
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
  const CircularProgressBinding({super.key, this.text = 'Syncing universe...'});

  @override
  Widget build(BuildContext context) {
    return AnimatedStartupCover(statusText: text);
  }
}
