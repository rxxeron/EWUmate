import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

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
  }

  Future<void> _checkStatus() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Smooth UX
    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;
    debugPrint("CheckAuth: User is ${user?.id}");

    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    try {
      debugPrint("CheckAuth: Fetching user profile...");
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single()
          .timeout(const Duration(seconds: 5));

      final status =
          data['onboarding_status'] ?? data['onboardingStatus'] ?? '';
      debugPrint("CheckAuth: Status is $status");

      if (mounted) {
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
    } catch (e) {
      debugPrint("CheckAuth: Error/Timeout $e");
      if (mounted) context.go('/login');
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
