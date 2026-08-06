import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PlayStoreReviewDialog extends StatelessWidget {
  static const String _kReviewDismissedKey = 'playstore_review_dismissed';
  static const String _kLaunchCountKey = 'app_launch_count_for_review';
  static const String _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.ewumate.app';

  const PlayStoreReviewDialog({super.key});

  /// Check whether we should prompt the user for a review on Play Store
  static Future<void> checkAndShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    
    final bool isDismissed = prefs.getBool(_kReviewDismissedKey) ?? false;
    if (isDismissed) return;

    int launchCount = prefs.getInt(_kLaunchCountKey) ?? 0;
    launchCount++;
    await prefs.setInt(_kLaunchCountKey, launchCount);

    // Prompt on 3rd launch or every 10th launch after
    if (launchCount == 3 || (launchCount > 3 && launchCount % 10 == 0)) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => const PlayStoreReviewDialog(),
      );
    }
  }

  static Future<void> _openPlayStore(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReviewDismissedKey, true); // Don't ask again once clicked

    final Uri url = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    if (context.mounted) Navigator.pop(context);
  }

  static Future<void> _remindLater(BuildContext context) async {
    if (context.mounted) Navigator.pop(context);
  }

  static Future<void> _neverAskAgain(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReviewDismissedKey, true);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.star_rounded, color: Colors.amber, size: 28),
          SizedBox(width: 8),
          Expanded(child: Text('Enjoying EWUmate?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
        ],
      ),
      content: const Text(
        'If you find EWUmate helpful for your university routine and tasks, please take a moment to leave us a 5-star rating on Google Play Store! Your support keeps us improving.',
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => _neverAskAgain(context),
          child: const Text('Never', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () => _remindLater(context),
          child: const Text('Later'),
        ),
        ElevatedButton.icon(
          onPressed: () => _openPlayStore(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade800,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.rate_review, size: 18),
          label: const Text('Rate 5 Stars'),
        ),
      ],
    );
  }
}
