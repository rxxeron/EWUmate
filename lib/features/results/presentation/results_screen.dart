import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_kit.dart';
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

    return FullGradientScaffold(
      appBar: AppBar(
        title: Text(
          "Academic Results",
          style: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allSemesterSummariesProvider);
          ref.invalidate(userProfileProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppColors.primaryCyan,
        backgroundColor: AppColors.surfaceNavyBlue,
        child: StreamBuilder(
          stream: profileStream,
          builder: (context, profileSnapshot) {
            final profileData = profileSnapshot.data;

            return summariesAsync.when(
              data: (summaries) {
                if (summaries.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: AppColors.primaryCyan.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.25), width: 1.5),
                              ),
                              child: const Icon(Icons.school_outlined, size: 32, color: AppColors.primaryCyan),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              "No Academic History Found",
                              style: GoogleFonts.sora(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Completed courses and semester results will appear here.",
                              style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, profileData),
                        const SizedBox(height: 16),
                        _buildSummaryHero(context, profileData, summaries.length),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.history_edu_rounded, color: AppColors.primaryCyan, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "SEMESTER BREAKDOWN",
                              style: GoogleFonts.sora(
                                color: AppColors.secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...summaries.map(
                          (sem) => _buildSemesterBlock(context, sem),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
              error: (e, _) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: 500,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    AuthErrorUtils.getFriendlyMessage(e),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(color: Colors.redAccent),
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
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: AppColors.primaryCyan,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "EAST WEST UNIVERSITY",
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        "Official Academic Record",
                        style: GoogleFonts.sora(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "VERIFIED",
                  style: GoogleFonts.sora(
                    color: const Color(0xFF10B981),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "STUDENT NAME",
                      style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profileData?.fullName ?? 'Student',
                      style: GoogleFonts.sora(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "STUDENT ID",
                      style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profileData?.studentId ?? 'N/A',
                      style: GoogleFonts.sora(color: AppColors.primaryCyan, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHero(BuildContext context, dynamic profileData, int semesterCount) {
    final double cgpa = (profileData?.cgpa is num) ? (profileData.cgpa as num).toDouble() : 0.0;
    final double credits = (profileData?.creditsEarned is num) ? (profileData.creditsEarned as num).toDouble() : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceNavyBlue,
            AppColors.surfaceNavyBlue.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCyan.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // CGPA Circle Badge
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cgpa.toStringAsFixed(2),
                    style: GoogleFonts.sora(
                      color: AppColors.primaryNavy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'CGPA',
                    style: GoogleFonts.sora(
                      color: AppColors.primaryNavy.withValues(alpha: 0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),

          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Credits Earned',
                      style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 12),
                    ),
                    Text(
                      credits.toStringAsFixed(1),
                      style: GoogleFonts.sora(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Semesters Completed',
                      style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 12),
                    ),
                    Text(
                      '$semesterCount',
                      style: GoogleFonts.sora(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Academic Standing',
                      style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 12),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cgpa >= 2.0 ? 'Good' : 'Probation',
                        style: GoogleFonts.sora(
                          color: cgpa >= 2.0 ? const Color(0xFF10B981) : Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterBlock(BuildContext context, dynamic sem) {
    final List<dynamic> courses = sem.courses ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavyBlue.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatSemesterName(sem.semesterCode),
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "TGPA: ${(sem.tgpa ?? 0.0).toStringAsFixed(2)}",
                        style: GoogleFonts.sora(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: AppColors.primaryCyan,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "CGPA: ${(sem.cgpa ?? 0.0).toStringAsFixed(2)}",
                        style: GoogleFonts.sora(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Table header
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text("COURSE", style: _tableHeaderStyle),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text("CR", textAlign: TextAlign.center, style: _tableHeaderStyle),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text("GRD", textAlign: TextAlign.center, style: _tableHeaderStyle),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text("GP", textAlign: TextAlign.right, style: _tableHeaderStyle),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                const SizedBox(height: 8),

                // Table rows
                ...courses.map((c) {
                  if (c == null || c is! Map) return const SizedBox();

                  final double credits = double.tryParse(c['credits']?.toString() ?? '0') ?? 0.0;
                  final double point = double.tryParse(c['point']?.toString() ?? '0') ?? 0.0;
                  final String grade = c['grade']?.toString() ?? '-';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            c['code']?.toString() ?? '',
                            style: GoogleFonts.sora(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            credits.toStringAsFixed(1),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 12),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getGradeColor(grade).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                grade,
                                style: GoogleFonts.sora(
                                  color: _getGradeColor(grade),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            point.toStringAsFixed(2),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.sora(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _tableHeaderStyle => GoogleFonts.sora(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.secondaryText,
        letterSpacing: 0.8,
      );

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return const Color(0xFF10B981);
    if (grade.startsWith('B')) return AppColors.primaryCyan;
    if (grade.startsWith('C')) return const Color(0xFFF59E0B);
    if (grade.startsWith('D')) return Colors.orange;
    if (grade.startsWith('F')) return Colors.redAccent;
    return AppColors.secondaryText;
  }

  String _formatSemesterName(String code) {
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
