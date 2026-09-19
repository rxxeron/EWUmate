import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ewu_theme_extension.dart';

class FacultyReviewsSpotlightDialog extends StatelessWidget {
  static const String _kSpotlightDismissedKey = 'has_seen_faculty_reviews_spotlight_v1';

  const FacultyReviewsSpotlightDialog({super.key});

  /// Check whether the user has already seen this announcement; if not, display it.
  static Future<void> checkAndShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeen = prefs.getBool(_kSpotlightDismissedKey) ?? false;
    if (hasSeen) return;

    // Small delay to ensure the dashboard transition has stabilized
    await Future.delayed(const Duration(milliseconds: 600));
    if (!context.mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'FacultyReviewsSpotlight',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, __) => const FacultyReviewsSpotlightDialog(),
    );
  }

  static Future<void> _markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSpotlightDismissedKey, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1425).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.primaryCyan.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withValues(alpha: 0.15),
                  blurRadius: 32,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top glowing icon badge
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.primaryCyan.withValues(alpha: 0.35),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0F223D),
                            border: Border.all(
                              color: AppColors.primaryCyan.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryCyan.withValues(alpha: 0.25),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.rate_review_rounded,
                            color: AppColors.primaryCyan,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Pill
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryCyan.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryCyan, size: 12),
                          const SizedBox(width: 5),
                          Text(
                            "NEW FEATURE",
                            style: GoogleFonts.sora(
                              color: AppColors.primaryCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Headline
                  Text(
                    "Faculty Reviews Are Live!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    "Make smarter advising choices with authentic course-wise evaluations and scorecards from fellow EWU students.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3 Feature Highlights
                  _buildFeatureRow(
                    icon: Icons.analytics_outlined,
                    iconColor: const Color(0xFF10B981),
                    title: "Multidimensional Scorecards",
                    description: "Lecture clarity, grading fairness, exam alignment, and consultation availability.",
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(
                    icon: Icons.menu_book_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: "Workload & Teaching Style",
                    description: "Find out if courses are slide-heavy, exam-aligned, or require mandatory textbooks.",
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(
                    icon: Icons.lightbulb_outline_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: "Insider Exam Tips & Reviews",
                    description: "Read real survival tips from seniors and submit your own verified course reviews.",
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  InkWell(
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      await _markDismissed();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        context.push('/services/faculty-directory');
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00E5FF),
                            Color(0xFF0091EA),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Explore Faculty Reviews",
                            style: GoogleFonts.sora(
                              color: const Color(0xFF060B18),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF060B18),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await _markDismissed();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: Text(
                      "Maybe Later",
                      style: GoogleFonts.sora(
                        color: colors.textTertiary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.sora(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
