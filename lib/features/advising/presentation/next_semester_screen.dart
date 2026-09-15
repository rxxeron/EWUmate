import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../course_browser/presentation/providers/course_browser_providers.dart';

/// Legacy NextSemesterScreen redirected to unified CourseBrowserScreen.
class NextSemesterScreen extends ConsumerStatefulWidget {
  const NextSemesterScreen({super.key});

  @override
  ConsumerState<NextSemesterScreen> createState() => _NextSemesterScreenState();
}

class _NextSemesterScreenState extends ConsumerState<NextSemesterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedSemesterScopeProvider.notifier).state = SemesterScope.upcoming;
      if (mounted) {
        context.go('/courses');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF04101E),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
