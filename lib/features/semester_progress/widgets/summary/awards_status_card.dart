import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ewumate/core/theme/app_colors.dart';
import 'package:ewumate/core/theme/ewu_theme_extension.dart';
import 'package:ewumate/core/utils/error_utils.dart';
import '../../semester_summary_providers.dart';

class AwardsStatusCard extends StatelessWidget {
  final AsyncValue<List<ScholarshipAward>> awardsAsync;

  const AwardsStatusCard({
    super.key,
    required this.awardsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;

    return awardsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: colors.primaryCyan)),
      error: (e, _) => Text(AuthErrorUtils.getFriendlyMessage(e), style: GoogleFonts.sora(color: AppColors.error)),
      data: (awards) {
        if (awards.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surfaceNavyBlue,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.isDark ? Colors.white.withValues(alpha: 0.08) : colors.borderSubtle),
            ),
            child: Column(
              children: [
                Icon(Icons.workspace_premium_outlined, color: colors.secondaryText, size: 40),
                const SizedBox(height: 12),
                Text(
                  'No Active Scholarship Awards',
                  style: GoogleFonts.sora(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Maintain your CGPA at or above the eligibility threshold to qualify for tuition waivers.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(color: colors.secondaryText, fontSize: 11),
                ),
              ],
            ),
          );
        }

        return Column(
          children: awards.map((award) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surfaceNavyBlue,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.primaryCyan.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primaryCyan.withValues(alpha: 0.15),
                    ),
                    child: Icon(Icons.workspace_premium_rounded, color: colors.primaryCyan, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          award.tier,
                          style: GoogleFonts.sora(color: colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Text(
                          '${award.waiver.toStringAsFixed(0)}% Tuition Waiver · Year ${award.forYear}',
                          style: GoogleFonts.sora(color: colors.primaryCyan, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        if (award.reason.isNotEmpty)
                          Text(award.reason, style: GoogleFonts.sora(color: colors.secondaryText, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
