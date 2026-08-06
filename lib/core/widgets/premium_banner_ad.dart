import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feature_flag_provider.dart';

class PremiumBannerAd extends ConsumerWidget {
  final EdgeInsetsGeometry? margin;
  final String screenName;

  const PremiumBannerAd({
    super.key,
    required this.screenName,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use feature flag to control custom banner visibility
    final bannerEnabled = ref.watch(isAdEnabledForProvider('banner'));
    if (!bannerEnabled) {
      return const SizedBox.shrink();
    }

    const double adWidth = 320;
    const double adHeight = 50;

    return Center(
      child: Image.network(
        'https://example.com/custom_banner.jpg', // Replace with your admin-provided URL
        width: adWidth,
        height: adHeight,
        fit: BoxFit.cover,
      ),
    );
  }
}
