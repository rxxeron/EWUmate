import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ewumate/core/theme/app_colors.dart';
import 'package:ewumate/core/theme/ewu_theme_extension.dart';
import 'package:ewumate/core/utils/error_utils.dart';
import '../../semester_summary_providers.dart';

class ScholarshipSelectorCard extends ConsumerWidget {
  final AsyncValue policyAsync;
  final String? targetTier;

  const ScholarshipSelectorCard({
    super.key,
    required this.policyAsync,
    required this.targetTier,
  });

  Widget _buildTierCard(
    BuildContext context,
    WidgetRef ref,
    String name,
    double cgpaReq,
    String? currentTarget,
    Color brandColor,
  ) {
    final colors = context.ewuColors;
    final isSelected = currentTarget == name || (currentTarget == null && name == 'Medha Lalon');

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(scholarshipTargetProvider.notifier).updateTarget(name);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? brandColor.withValues(alpha: 0.16) : colors.surfaceNavyBlue,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? brandColor : (colors.isDark ? Colors.white.withValues(alpha: 0.08) : colors.borderSubtle),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: brandColor.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 3))]
                : null,
          ),
          child: Column(
            children: [
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(
                  color: isSelected ? colors.textPrimary : colors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? brandColor.withValues(alpha: 0.25) : Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${cgpaReq.toStringAsFixed(2)} CGPA',
                  style: GoogleFonts.sora(
                    color: isSelected ? brandColor : colors.secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ewuColors;
    return policyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
      error: (e, _) => Text(
        AuthErrorUtils.getFriendlyMessage(e),
        textAlign: TextAlign.center,
        style: GoogleFonts.sora(color: AppColors.error, fontSize: 12),
      ),
      data: (policy) {
        if (policy == null) {
          return Text(
            'No scholarship policy mapped for your program yet.',
            style: GoogleFonts.sora(color: Colors.white54, fontStyle: FontStyle.italic),
          );
        }

        return Row(
          children: [
            _buildTierCard(context, ref, 'Medha Lalon', policy.tierMedhaLalonMin, targetTier, colors.primaryCyan),
            const SizedBox(width: 10),
            _buildTierCard(context, ref, "Dean's List", policy.tierDeansListMin, targetTier, colors.primaryCyan),
            const SizedBox(width: 10),
            _buildTierCard(context, ref, 'Merit 100%', policy.tierMerit100Min, targetTier, colors.primaryCyan),
          ],
        );
      },
    );
  }
}
