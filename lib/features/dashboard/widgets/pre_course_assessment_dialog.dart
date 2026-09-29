import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ewu_theme_extension.dart';

class PreCourseAssessmentDialog extends StatefulWidget {
  final Map<String, dynamic>? remoteConfig;
  final String countKey;
  final int maxImpressions;

  const PreCourseAssessmentDialog({
    super.key,
    this.remoteConfig,
    this.countKey = 'popup_impressions_pre_course_assessment_v1',
    this.maxImpressions = 3,
  });

  /// Evaluates remote configuration from Supabase `app_config`, impression count,
  /// and gap days cooldown before showing the dialog.
  /// All parameters (active status, campaign ID, max impressions, gap days, texts)
  /// are remotely controllable from the Admin Panel.
  static Future<void> checkAndShow(BuildContext context) async {
    // 1. Fetch remote config from Supabase app_config (or fall back to defaults)
    Map<String, dynamic> config = {
      'is_active': true,
      'campaign_id': 'pre_course_assessment_v1',
      'max_impressions': 3,
      'gap_days': 4,
    };

    try {
      final res = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', 'feature_announcement_popup')
          .maybeSingle();

      if (res != null && res['value'] != null) {
        final val = res['value'];
        if (val is Map) {
          config = {...config, ...Map<String, dynamic>.from(val)};
        } else if (val is String) {
          final decoded = jsonDecode(val);
          if (decoded is Map) {
            config = {...config, ...Map<String, dynamic>.from(decoded)};
          }
        }
      }
    } catch (e) {
      debugPrint('[PreCourseAssessmentDialog] Remote config fetch error: $e');
    }

    // 2. If remotely disabled, do not show
    if (config['is_active'] != true) return;

    final String campaignId = config['campaign_id']?.toString() ?? 'pre_course_assessment_v1';
    final int maxImpressions = int.tryParse(config['max_impressions']?.toString() ?? '3') ?? 3;
    final int gapDays = int.tryParse(config['gap_days']?.toString() ?? '4') ?? 4;

    final String countKey = 'popup_impressions_$campaignId';
    final String lastShownKey = 'popup_last_shown_$campaignId';

    final prefs = await SharedPreferences.getInstance();
    final int count = prefs.getInt(countKey) ?? 0;
    if (count >= maxImpressions) return;

    final int lastShownMs = prefs.getInt(lastShownKey) ?? 0;
    final now = DateTime.now();

    if (lastShownMs > 0) {
      final lastShown = DateTime.fromMillisecondsSinceEpoch(lastShownMs);
      final difference = now.difference(lastShown);
      if (difference.inDays < gapDays) {
        // Less than required gap days have passed
        return;
      }
    }

    // Delay slightly to let the dashboard render and settle
    await Future.delayed(const Duration(milliseconds: 900));
    if (!context.mounted) return;

    // Record this impression (increment count & set timestamp)
    await prefs.setInt(countKey, count + 1);
    await prefs.setInt(lastShownKey, now.millisecondsSinceEpoch);

    if (!context.mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PreCourseAssessmentNotice',
      barrierColor: Colors.black.withValues(alpha: 0.82),
      transitionDuration: const Duration(milliseconds: 400),
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
      pageBuilder: (context, _, __) => PreCourseAssessmentDialog(
        remoteConfig: config,
        countKey: countKey,
        maxImpressions: maxImpressions,
      ),
    );
  }

  static Future<void> markNeverShowAgain(String countKey, int maxImpressions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(countKey, maxImpressions);
  }

  @override
  State<PreCourseAssessmentDialog> createState() => _PreCourseAssessmentDialogState();
}

class _PreCourseAssessmentDialogState extends State<PreCourseAssessmentDialog> {
  bool _showFullNotice = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final size = MediaQuery.of(context).size;
    final cfg = widget.remoteConfig;

    final badgeText = cfg?['badge_text']?.toString() ?? "MANDATORY PRE-COURSE ASSESSMENT";
    final titleText = cfg?['title']?.toString() ?? "Advising Guide & Faculty Reviews Are Live!";
    final descText = cfg?['description']?.toString() ??
        "Per the Registrar's notice, courses selected in Pre-Course Assessment are final. There is NO add period after registration. Use EWUMate's new tools to verify prerequisites and faculty ratings before submitting.";

    final cta1Label = cfg?['cta1_text']?.toString() ?? "Open Advising Guide";
    final cta1Path = cfg?['cta1_route']?.toString() ?? "/services/advising-guide";
    final cta2Label = cfg?['cta2_text']?.toString() ?? "Browse Faculty Reviews";
    final cta2Path = cfg?['cta2_route']?.toString() ?? "/services/faculty-directory";

    final bool showFeatures = cfg?['show_features'] != false;
    final feature1Title = cfg?['feature1_title']?.toString() ?? "Course Advising & Prerequisites";
    final feature1Desc = cfg?['feature1_description']?.toString() ?? "Check course eligibility in real time, view locked courses with prerequisite reasons, and follow your curriculum pathway.";
    final feature1Badge = cfg?['feature1_badge']?.toString() ?? "ELIGIBILITY ENGINE";
    final feature1Action = cfg?['feature1_action']?.toString() ?? "Open Guide";
    final feature1Route = cfg?['feature1_route']?.toString() ?? cta1Path;

    final feature2Title = cfg?['feature2_title']?.toString() ?? "Faculty Ratings & Reviews";
    final feature2Desc = cfg?['feature2_description']?.toString() ?? "Browse verified student feedback, grading tendencies, teaching styles, and office hours to plan optimal sections.";
    final feature2Badge = cfg?['feature2_badge']?.toString() ?? "STUDENT REVIEWS";
    final feature2Action = cfg?['feature2_action']?.toString() ?? "View Faculty";
    final feature2Route = cfg?['feature2_route']?.toString() ?? cta2Path;

    final rawNotices = cfg?['notice_items'];
    final List<String> noticeItems = (rawNotices is List && rawNotices.isNotEmpty)
        ? rawNotices.map((e) => e.toString()).toList()
        : [
            "Courses selected are final. Only pre-assessed courses will appear during advising.",
            "NO period for adding courses after registration.",
            "Fulfill all prerequisite requirements before selecting any course.",
            "Carefully review graduation curriculum and credit limits.",
            "Failure to complete Pre-Course Assessment makes you ineligible for registration.",
          ];

    final noticeTitle = cfg?['notice_title']?.toString() ?? "Read Key Notice & Rules";

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: size.height * 0.88,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F172A),
                  const Color(0xFF0B132B),
                  colors.surfaceNavyBlue,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                  blurRadius: 36,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Dual Glowing Icon Header (Compass & Star)
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF38BDF8).withValues(alpha: 0.35),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0C192E),
                                border: Border.all(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_tree_rounded,
                                    color: Color(0xFF38BDF8),
                                    size: 22,
                                  ),
                                  SizedBox(width: 3),
                                  Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFBBF24),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. Alert Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFFBBF24),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                badgeText,
                                style: GoogleFonts.sora(
                                  color: const Color(0xFFFBBF24),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3. Headline
                      Text(
                        titleText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 4. Critical Context Callout
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          descText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.sora(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. Feature Highlight 1
                      if (showFeatures) ...[
                        _buildFeatureTile(
                          context: context,
                          icon: Icons.account_tree_rounded,
                          iconColor: const Color(0xFF38BDF8),
                          title: feature1Title,
                          description: feature1Desc,
                          badge: feature1Badge,
                          actionLabel: feature1Action,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                            context.push(feature1Route);
                          },
                        ),
                        const SizedBox(height: 10),

                        // 6. Feature Highlight 2
                        _buildFeatureTile(
                          context: context,
                          icon: Icons.rate_review_rounded,
                          iconColor: const Color(0xFFFBBF24),
                          title: feature2Title,
                          description: feature2Desc,
                          badge: feature2Badge,
                          actionLabel: feature2Action,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                            context.push(feature2Route);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // 7. Expandable Notice Accordion (Dynamic from noticeItems)
                      if (noticeItems.isNotEmpty) ...[
                        InkWell(
                          onTap: () => setState(() => _showFullNotice = !_showFullNotice),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _showFullNotice ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                  color: colors.secondaryText,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _showFullNotice ? "Hide Details" : noticeTitle,
                                    style: GoogleFonts.sora(
                                      color: colors.secondaryText,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  "Details",
                                  style: GoogleFonts.sora(
                                    color: const Color(0xFF38BDF8),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_showFullNotice) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF070E1C),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0; i < noticeItems.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 6),
                                  _buildNoticeBullet("${i + 1}", noticeItems[i]),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 18),

                      // 8. Action Buttons
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                          context.push(cta1Path);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCyan,
                          foregroundColor: const Color(0xFF070E1C),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.explore_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              cta1Label,
                              style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                          context.push(cta2Path);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.rate_review_rounded, size: 16, color: Color(0xFFFBBF24)),
                            const SizedBox(width: 8),
                            Text(
                              cta2Label,
                              style: GoogleFonts.sora(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 9. Dismiss Options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              PreCourseAssessmentDialog.markNeverShowAgain(
                                widget.countKey,
                                widget.maxImpressions,
                              );
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: colors.secondaryText.withValues(alpha: 0.7),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Don't show again",
                              style: GoogleFonts.sora(fontSize: 11),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.secondaryText,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Got it",
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Top right close button
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      padding: const EdgeInsets.all(6),
                      minimumSize: Size.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String badge,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: iconColor.withValues(alpha: 0.15),
        highlightColor: iconColor.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1E38).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.sora(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.sora(
                              color: iconColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.sora(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          actionLabel,
                          style: GoogleFonts.sora(
                            color: iconColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: iconColor, size: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeBullet(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
          ),
          child: Text(
            number,
            style: GoogleFonts.sora(
              color: const Color(0xFF38BDF8),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.sora(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
