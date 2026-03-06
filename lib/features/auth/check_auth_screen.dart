import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../calendar/academic_repository.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/offline_cache_service.dart';

class CheckAuthScreen extends StatefulWidget {
  const CheckAuthScreen({super.key});

  @override
  State<CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends State<CheckAuthScreen> {
  @override
  void initState() {
    super.initState();
    _checkStatus();
    
    // Emergency navigation if nothing happens in 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        final currentPath = GoRouterState.of(context).uri.toString();
        if (currentPath == '/' || currentPath == '/check-auth') {
          debugPrint("CheckAuth: Emergency navigation triggered from path: $currentPath");
          context.go('/dashboard');
        }
      }
    });
  }

  Future<void> _checkStatus() async {
    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;
    debugPrint("CheckAuth: Start - User ID: ${user?.id}");

    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    // Parallel check: Cache vs Connectivity
    final cache = OfflineCacheService();
    final cachedData = cache.getCachedUserMetadata();
    
    // 1. If we have cache, we are DONE. GO!
    if (cachedData != null) {
      debugPrint("CheckAuth: Cache hit! Navigating...");
      _navigateBasedOnStatus(cachedData);
      _syncMetadataInBackground(user.id);
      return;
    }

    // 2. No cache. Check connectivity with a TIGHT timeout.
    try {
      debugPrint("CheckAuth: No cache. Checking connectivity...");
      final isOnline = await ConnectivityService().isOnline().timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () => false,
      );

      if (!isOnline) {
        debugPrint("CheckAuth: Offline and no cache. Defaulting to Dashboard.");
        if (mounted) context.go('/dashboard');
        return;
      }

      debugPrint("CheckAuth: Online. Fetching fresh metadata...");
      final data = await _fetchMetadata(user.id).timeout(const Duration(seconds: 3));
      if (data != null) {
        _navigateBasedOnStatus(data);
        return;
      }
    } catch (e) {
      debugPrint("CheckAuth: Initial check failed or timed out: $e");
    }

    // Final Fallback
    debugPrint("CheckAuth: Final fallback to Dashboard.");
    if (mounted) context.go('/dashboard');
  }

  Future<Map<String, dynamic>?> _fetchMetadata(String userId) async {
    try {
      final academicRepo = AcademicRepository();
      await academicRepo.promoteSemester().timeout(const Duration(seconds: 2)).catchError((_) => null);

      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single()
          .timeout(const Duration(seconds: 3));

      await OfflineCacheService().cacheUserMetadata({
        'onboarding_status': data['onboarding_status'] ?? data['onboardingStatus'] ?? '',
        'force_grade_entry': data['force_grade_entry'] ?? false,
      });
      return data;
    } catch (e) {
      debugPrint("CheckAuth: Fetch Error $e");
      return null;
    }
  }

  void _syncMetadataInBackground(String userId) {
    _fetchMetadata(userId).then((data) {
       debugPrint("CheckAuth: Background sync completed.");
    }).catchError((e) {
       debugPrint("CheckAuth: Background sync failed $e");
    });
  }

  void _navigateBasedOnStatus(Map<String, dynamic> data) {
    if (!mounted) return;

    final status = data['onboarding_status'] ?? data['onboardingStatus'] ?? '';
    final forceEntry = data['force_grade_entry'] ?? false;
    debugPrint("CheckAuth: Navigating with Status: $status, forceEntry: $forceEntry");

    if (forceEntry) {
      context.go('/gatekeeper');
      return;
    }

    if (status == 'onboarded') {
      context.go('/dashboard');
    } else if (status == 'registered') {
      context.go('/onboarding/program');
    } else if (status == 'program_selected') {
      context.go('/onboarding/course-history');
    } else {
      context.go('/onboarding/program');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
