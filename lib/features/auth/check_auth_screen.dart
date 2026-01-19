import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final user = FirebaseAuth.instance.currentUser;
    debugPrint("CheckAuth: User is ${user?.uid}");

    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    try {
      debugPrint("CheckAuth: Fetching user doc...");
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      debugPrint("CheckAuth: Doc exists? ${doc.exists}");
      if (!doc.exists) {
        if (mounted) context.go('/login');
        return;
      }

      final status = doc.data()?['onboardingStatus'] ?? '';
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
