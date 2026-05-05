import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/progress_repository.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/utils/error_utils.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) {
        ref.invalidate(allSemesterSummariesProvider);
        ref.invalidate(userProfileProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final summariesAsync = ref.watch(allSemesterSummariesProvider);
    final profileStream = user != null
        ? ref.watch(profileRepositoryProvider).streamProfile(user.id)
        : const Stream.empty();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Academic Results History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allSemesterSummariesProvider);
          ref.invalidate(userProfileProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: Colors.blueAccent,
        backgroundColor: const Color(0xFF1E1E2E),
        child: StreamBuilder(
          stream: profileStream,
          builder: (context, profileSnapshot) {
            final profileData = profileSnapshot.data;

            return summariesAsync.when(
              data: (summaries) {
                if (summaries.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      alignment: Alignment.center,
                      child: const Text(
                        "No academic history found.",
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white54),
                      ),
                    ),
                  );
                }
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, profileData),
                      const Divider(thickness: 1),
                      const SizedBox(height: 10),
                      ...summaries.map(
                        (sem) => _buildSemesterBlock(context, sem),
                      ),
                      const Divider(thickness: 1),
                      _buildSummary(context, profileData),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: 500,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    AuthErrorUtils.getFriendlyMessage(e),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic profileData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Formal University Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "EAST WEST UNIVERSITY",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Serif',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Student's Copy",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.school,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
          ],
        ),
        const SizedBox(height: 15),

        // 2. Student Info Map
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow("Name:", profileData?.fullName ?? 'Student', context),
              const SizedBox(height: 4),
              _infoRow("ID:", profileData?.studentId ?? 'N/A', context),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _infoRow(String label, String value, BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSemesterBlock(BuildContext context, dynamic sem) {
    final List<dynamic> courses = sem.courses ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatSemesterName(sem.semesterCode),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Divider(),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.5), // Course
              1: FlexColumnWidth(3.0), // Title
              2: FlexColumnWidth(0.8), // cr
              3: FlexColumnWidth(0.8), // grd
              4: FlexColumnWidth(0.8), // gp
              5: FlexColumnWidth(1.0), // gpacr
            },
            children: [
              TableRow(
                children: [
                  _tableHeader("Course", context),
                  _tableHeader("Title", context),
                  _tableHeader("cr", context, align: TextAlign.right),
                  _tableHeader("grd", context, align: TextAlign.right),
                  _tableHeader("gp", context, align: TextAlign.right),
                  _tableHeader("gpacr", context, align: TextAlign.right),
                ],
              ),
              const TableRow(
                children: [
                  SizedBox(height: 5),
                  SizedBox(),
                  SizedBox(),
                  SizedBox(),
                  SizedBox(),
                  SizedBox(),
                ],
              ),
              ...courses.map((c) {
                if (c == null || c is! Map) {
                  return const TableRow(
                    children: [
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                    ],
                  );
                }

                final double credits =
                    double.tryParse(c['credits']?.toString() ?? '0') ?? 0.0;
                final double point =
                    double.tryParse(c['point']?.toString() ?? '0') ?? 0.0;
                final double gpacr = credits * point;

                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        c['code']?.toString() ?? '',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        c['code']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Text(
                      credits.toStringAsFixed(1),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      c['grade']?.toString() ?? '',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      point.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      gpacr.toStringAsFixed(1),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "CGPA: ${(sem.cgpa ?? 0.0).toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  Text(
                    "Term GPA: ${(sem.tgpa ?? 0.0).toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(
    String text,
    BuildContext context, {
    TextAlign align = TextAlign.left,
  }) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildSummary(BuildContext context, dynamic profileData) {
    if (profileData == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "CGPA: ${(profileData.cgpa ?? 0.0).toStringAsFixed(2)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            Text(
              "Credit Earned: ${(profileData.creditsEarned ?? 0.0).toStringAsFixed(2)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSemesterName(String code) {
    // Basic formatting: spring2026 -> Spring 2026
    if (code.isEmpty) return code;
    try {
      final clean = code.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final match = RegExp(r'^([a-z]+)(\d+)$').firstMatch(clean);
      if (match != null) {
        final sem = match.group(1)!;
        final yr = match.group(2)!;
        return "${sem[0].toUpperCase()}${sem.substring(1)} $yr";
      }
    } catch (_) {}
    return code;
  }
}
