import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/feature_flag_provider.dart';
import 'glass_kit.dart';

class PremiumNativeAd extends ConsumerStatefulWidget {
  final EdgeInsetsGeometry? margin;
  final bool isTile;
  final String screenName;

  const PremiumNativeAd({
    super.key,
    required this.screenName,
    this.margin,
    this.isTile = false,
  });

  @override
  ConsumerState<PremiumNativeAd> createState() => _PremiumNativeAdState();
}

class _PremiumNativeAdState extends ConsumerState<PremiumNativeAd> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _hasAdFailed = false;

  // Served Native Ad Unit ID
  String get _productionAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7033696898787402/9759985268';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-7033696898787402/9759985268';
    }
    return '';
  }

  String get _testAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/2247696110'; // Android Native Advanced Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/3986624511'; // iOS Native Advanced Test ID
    }
    return '';
  }

  String get adUnitId {
    if (kDebugMode) {
      return _testAdUnitId;
    }
    return _productionAdUnitId;
  }

  @override
  void initState() {
    super.initState();
  }

  void _loadNativeAd({bool useFallback = false}) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      setState(() => _hasAdFailed = true);
      return;
    }

    final targetUnitId = useFallback ? _testAdUnitId : adUnitId;

    // Define colors dynamically to match grid tile pastel red vs dark glassmorphic mode
    final Color mainBgColor = widget.isTile ? const Color(0xFFFEE2E2) : const Color(0xFF151D30);
    final Color primaryTxtColor = widget.isTile ? const Color(0xFF991B1B) : Colors.white;
    final Color secondaryTxtColor = widget.isTile ? const Color(0xFFB91C1C) : Colors.white70;
    final Color tertiaryTxtColor = widget.isTile ? const Color(0xFFDC2626) : Colors.white54;
    final Color ctaTextColor = widget.isTile ? Colors.white : Colors.cyanAccent;
    final Color ctaBgColor = widget.isTile ? const Color(0xFF991B1B) : const Color(0xFF1E293B).withValues(alpha: 0.8);

    _nativeAd = NativeAd(
      adUnitId: targetUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: mainBgColor,
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: ctaTextColor,
          backgroundColor: ctaBgColor,
          size: 13.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: primaryTxtColor,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: secondaryTxtColor,
          size: 11.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: tertiaryTxtColor,
          size: 10.0,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _hasAdFailed = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('PremiumNativeAd failed to load ($targetUnitId): $error');
          ad.dispose();

          // Fallback to test ID transparently if production ID fails
          if (!useFallback && targetUnitId == _productionAdUnitId) {
            if (mounted) {
              setState(() {
                _isAdLoaded = false;
                _hasAdFailed = false;
              });
              _loadNativeAd(useFallback: true);
            }
          } else {
            if (mounted) {
              setState(() {
                _isAdLoaded = false;
                _hasAdFailed = true;
              });
            }
          }
        },
      ),
    );

    try {
      _nativeAd!.load();
    } catch (e) {
      debugPrint('Error loading PremiumNativeAd: $e');
      if (mounted) {
        setState(() {
          _hasAdFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenAdsEnabled = ref.watch(isAdEnabledForProvider(widget.screenName));
    final nativeFormatEnabled = ref.watch(isAdEnabledForProvider('native'));
    final isAdAllowed = screenAdsEnabled && nativeFormatEnabled;

    if (!isAdAllowed) {
      if (_nativeAd != null) {
        _nativeAd!.dispose();
        _nativeAd = null;
        _isAdLoaded = false;
      }
      return const SizedBox.shrink();
    }

    // Trigger ad load asynchronously if it hasn't been initialized
    if (_nativeAd == null && !_hasAdFailed && !_isAdLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _nativeAd == null) {
          _loadNativeAd();
        }
      });
    }

    if (_hasAdFailed) {
      return const SizedBox.shrink(); // Hide ad slot cleanly if loading fails
    }

    if (widget.isTile) {
      final cardColor = const Color(0xFFFEE2E2); // Colors.red.shade100

      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _isAdLoaded && _nativeAd != null
                    ? AdWidget(ad: _nativeAd!)
                    : _buildSkeletonLoader(double.infinity),
              ),
            ),
          ],
        ),
      );
    }

    final double adHeight = 100;

    return Center(
      child: GlassContainer(
        margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        borderRadius: 16,
        borderColor: Colors.cyanAccent.withValues(alpha: 0.08),
        opacity: 0.05,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: adHeight,
              alignment: Alignment.center,
              child: _isAdLoaded && _nativeAd != null
                  ? AdWidget(ad: _nativeAd!)
                  : _buildSkeletonLoader(adHeight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(double height) {
    final indicatorColor = widget.isTile ? const Color(0xFF991B1B) : Colors.cyanAccent;
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: widget.isTile ? Colors.transparent : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: indicatorColor.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }
}
