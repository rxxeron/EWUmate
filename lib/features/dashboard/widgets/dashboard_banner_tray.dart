import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../../core/theme/ewu_theme_extension.dart';

class DashboardBannerTray extends ConsumerStatefulWidget {
  final bool showUpdateBanner;
  final String updateUrl;
  final VoidCallback onDismissUpdate;
  final bool showAdvisingBanner;
  final VoidCallback onAdvisingTap;
  final Map<String, dynamic>? semConfig;

  const DashboardBannerTray({
    super.key,
    required this.showUpdateBanner,
    required this.updateUrl,
    required this.onDismissUpdate,
    required this.showAdvisingBanner,
    required this.onAdvisingTap,
    this.semConfig,
  });

  @override
  ConsumerState<DashboardBannerTray> createState() => _DashboardBannerTrayState();
}

class _DashboardBannerTrayState extends ConsumerState<DashboardBannerTray> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final List<Widget> activeBanners = [];

    // 1. App Update Banner
    if (widget.showUpdateBanner) {
      activeBanners.add(_buildAlertCard(
        context,
        icon: Icons.system_update_rounded,
        iconColor: const Color(0xFF10B981),
        title: "App Update Available",
        subtitle: "A new version of EWUMate is ready with improvements.",
        actionLabel: "Update",
        onAction: () => url_launcher.launchUrl(Uri.parse(widget.updateUrl), mode: url_launcher.LaunchMode.externalApplication),
        onDismiss: widget.onDismissUpdate,
      ));
    }

    // 3. Advising Banner
    if (widget.showAdvisingBanner) {
      activeBanners.add(_buildAlertCard(
        context,
        icon: Icons.school_rounded,
        iconColor: const Color(0xFFF59E0B),
        title: "Advising Season Active",
        subtitle: "Check course prerequisites and plan next semester.",
        actionLabel: "Open Advising",
        onAction: widget.onAdvisingTap,
      ));
    }

    // 4. Semester Transition Banner
    if (widget.semConfig != null) {
      final startStr = widget.semConfig!['grade_submission_start'];
      final endStr = widget.semConfig!['grade_submission_end'];
      if (startStr != null && endStr != null) {
        final start = DateTime.tryParse(startStr.toString());
        final end = DateTime.tryParse(endStr.toString());
        final now = DateTime.now();
        if (start != null && end != null && now.isAfter(start) && now.isBefore(end)) {
          activeBanners.add(_buildAlertCard(
            context,
            icon: Icons.grade_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: "Grade Submission Window",
            subtitle: "Faculty grades are currently being finalized.",
            actionLabel: "View Results",
            onAction: () {},
          ));
        }
      }
    }

    if (activeBanners.isEmpty) return const SizedBox.shrink();

    // If only 1 banner, render directly
    if (activeBanners.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: activeBanners.first,
      );
    }

    // If multiple banners, render first with accordion toggle
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          activeBanners.first,
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            ...activeBanners.sublist(1).map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: b,
            )),
          ],
          const SizedBox(height: 4),
          Center(
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded
                          ? "Collapse alerts"
                          : "+${activeBanners.length - 1} more alert${activeBanners.length > 2 ? 's' : ''}",
                      style: GoogleFonts.sora(
                        color: colors.primaryCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: colors.primaryCyan,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
  }) {
    final colors = context.ewuColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue.withValues(alpha: colors.isDark ? 0.72 : 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    color: colors.primaryText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.sora(
                      color: colors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: iconColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.sora(
                    color: iconColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.close_rounded, size: 16, color: colors.secondaryText),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
