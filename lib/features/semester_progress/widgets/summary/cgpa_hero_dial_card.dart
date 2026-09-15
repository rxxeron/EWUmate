import 'package:ewumate/core/repositories/progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ewumate/core/models/profile.dart';
import 'package:ewumate/core/models/semester_analytics.dart';
import 'package:ewumate/core/providers/academic_providers.dart';
import 'package:ewumate/core/theme/ewu_theme_extension.dart';
import '../../semester_summary_providers.dart';

class CgpaHeroDialCard extends ConsumerWidget {
  final Profile? profile;
  final AsyncValue policyAsync;
  final SemesterAnalytics? analytics;
  final AsyncValue currentMarksAsync;
  final AsyncValue<List<ScholarshipAward>> awardsAsync;

  const CgpaHeroDialCard({
    super.key,
    required this.profile,
    required this.policyAsync,
    required this.analytics,
    required this.currentMarksAsync,
    required this.awardsAsync,
  });

  Widget _buildMetricTile({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    final colors = context.ewuColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.isDark ? Colors.white.withValues(alpha: 0.06) : colors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 16, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    color: colors.secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ewuColors;
    final policy = policyAsync.valueOrNull;

    final summariesRaw = ref.watch(allSemesterSummariesProvider).valueOrNull ?? [];
    final academicState = ref.watch(academicStateProvider).valueOrNull;
    final String? runningCode = academicState?.currentSemesterCode;
    final String? nextCode = academicState?.nextSemesterCode;

    final completedSummaries = summariesRaw.where((s) => s.semesterCode != runningCode && s.semesterCode != nextCode).toList();
    final double historyCgpa = completedSummaries.isNotEmpty ? (completedSummaries.last.cgpa ?? 0.0) : (profile?.cgpa ?? 0.0);

    final localProjectedSgpa = ref.watch(projectedSGPAProvider);
    final predictedSgpa = (localProjectedSgpa > 0) ? localProjectedSgpa : (analytics?.liveSgpa ?? 0.0);
    final predictedCgpa = ref.watch(projectedCGPAProvider).valueOrNull ?? profile?.cgpa ?? 0.0;
    final enrolledCredits = ref.watch(currentEnrolledCreditsProvider);

    final targetTier = ref.watch(scholarshipTargetProvider);
    double targetThreshold = 3.50;
    if (targetTier == "Dean's List") targetThreshold = policy?.tierDeansListMin ?? 3.75;
    if (targetTier == "Merit 100%") targetThreshold = policy?.tierMerit100Min ?? 3.90;
    if (targetTier == "Medha Lalon") targetThreshold = policy?.tierMedhaLalonMin ?? 3.50;

    final isOnTrack = predictedCgpa >= targetThreshold;

    final double cgpaDelta = predictedCgpa - historyCgpa;
    final bool isPositiveDelta = cgpaDelta >= 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colors.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : colors.borderSubtle,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.40)
                : const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          if (colors.isDark)
            BoxShadow(
              color: colors.primaryCyan.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          // Top live badge & on-track badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.primaryCyan.withValues(alpha: 0.30), width: 0.8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_graph_rounded, color: colors.primaryCyan, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      'LIVE PROJECTION',
                      style: GoogleFonts.sora(
                        color: colors.primaryCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnTrack ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isOnTrack ? const Color(0xFF10B981) : const Color(0xFFF59E0B), width: 1),
                ),
                child: Text(
                  isOnTrack ? 'ON TRACK' : 'AT RISK',
                  style: GoogleFonts.sora(
                    color: isOnTrack ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Central Hero CGPA Dial
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                predictedCgpa.toStringAsFixed(2),
                style: GoogleFonts.sora(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ 4.00',
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.secondaryText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Delta Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPositiveDelta ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFF43F5E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPositiveDelta ? const Color(0xFF10B981).withValues(alpha: 0.35) : const Color(0xFFF43F5E).withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositiveDelta ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 14,
                  color: isPositiveDelta ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                ),
                const SizedBox(width: 5),
                Text(
                  '${isPositiveDelta ? '+' : ''}${cgpaDelta.toStringAsFixed(2)} from last sem',
                  style: GoogleFonts.sora(
                    color: isPositiveDelta ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4 Flanking Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: 'Predicted SGPA',
                  value: predictedSgpa.toStringAsFixed(2),
                  icon: Icons.speed_rounded,
                  accentColor: colors.primaryCyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: 'Enrolled Cr',
                  value: '${enrolledCredits.toStringAsFixed(1)} Cr',
                  icon: Icons.school_rounded,
                  accentColor: colors.primaryCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: 'Total Earned',
                  value: '${(analytics?.completedCredit ?? profile?.totalCreditsEarned ?? 0.0).toStringAsFixed(1)} Cr',
                  icon: Icons.stars_rounded,
                  accentColor: colors.primaryCyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: 'Academic Standing',
                  value: predictedCgpa >= 3.75 ? "Dean's List" : (predictedCgpa >= 3.5 ? 'Distinction' : 'Good'),
                  icon: Icons.workspace_premium_rounded,
                  accentColor: colors.primaryCyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
