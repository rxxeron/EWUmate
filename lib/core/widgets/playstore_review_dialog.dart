import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class PlayStoreReviewDialog extends StatelessWidget {
  static const String _kReviewDismissedKey = 'playstore_review_v2_dismissed';
  static const String _kPlayStoreMarketUri = 'market://details?id=com.rxxeron.ewumate';
  static const String _kPlayStoreWebUrl = 'https://play.google.com/store/apps/details?id=com.rxxeron.ewumate';

  const PlayStoreReviewDialog({super.key});

  /// Check whether we should prompt the user for a review on Play Store
  static Future<void> checkAndShow(BuildContext context) async {
    // Only prompt on Android devices where Google Play Store exists
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final prefs = await SharedPreferences.getInstance();
    final bool isDismissed = prefs.getBool(_kReviewDismissedKey) ?? false;
    if (isDismissed) return;

    // Small delay so the dashboard transition and UI settle smoothly
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!context.mounted) return;

    // Check if the user hasn't seen the faculty reviews spotlight yet;
    // if not, let spotlight display first so we don't bombard them simultaneously.
    // They will see this review prompt on their next open/dashboard visit!
    final bool hasSeenSpotlight = prefs.getBool('has_seen_faculty_reviews_spotlight_v1') ?? false;
    if (!hasSeenSpotlight) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PlayStoreReview',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 320),
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
      pageBuilder: (context, _, __) => const PlayStoreReviewDialog(),
    );
  }

  /// Direct method to open Play Store for rating (used both in dialog and Drawer menu)
  static Future<void> openPlayStore([BuildContext? context]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReviewDismissedKey, true);

    final Uri marketUri = Uri.parse(_kPlayStoreMarketUri);
    final Uri webUri = Uri.parse(_kPlayStoreWebUrl);

    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    if (context != null && context.mounted) {
      Navigator.pop(context);
    }
  }

  static Future<void> _neverAskAgain(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReviewDismissedKey, true);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceNavyBlue.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Star Header Icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFF59E0B),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Enjoying EWUmate?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),

                // 5 Gold Stars Rating Visual
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.5),
                      child: Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Body text
                Text(
                  'If EWUmate makes your daily university routines, schedules, and exams easier, please take a moment to leave us a 5-star rating on Google Play Store!\nYour review directly supports our student development team.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 22),

                // Primary Action Button: Rate 5 Stars
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => openPlayStore(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rate_review_rounded, size: 18, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          'Rate 5 Stars on Play Store',
                          style: GoogleFonts.sora(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Secondary Actions: Maybe Later & Don't Ask Again
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => _neverAskAgain(context),
                      child: Text(
                        "Don't ask again",
                        style: GoogleFonts.sora(
                          fontSize: 11.5,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Maybe Later',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryCyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
