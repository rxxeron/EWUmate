import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/feature_flag_provider.dart';
import 'glass_kit.dart';

class PremiumBannerAd extends ConsumerStatefulWidget {
  final EdgeInsetsGeometry? margin;
  final String screenName;

  const PremiumBannerAd({
    super.key,
    required this.screenName,
    this.margin,
  });

  @override
  ConsumerState<PremiumBannerAd> createState() => _PremiumBannerAdState();
}

class _PremiumBannerAdState extends ConsumerState<PremiumBannerAd> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _hasAdFailed = false;

  // Served Ad Unit ID (Test unit fallback for local debugging, production ID for release)
  String get _productionAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7033696898787402/1582112346';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-7033696898787402/1582112346';
    }
    return '';
  }

  String get _testAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android Demo Banner Ad Unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS Demo Banner Ad Unit ID
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

  void _loadBannerAd({bool useFallback = false}) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      setState(() => _hasAdFailed = true);
      return;
    }

    final targetUnitId = useFallback ? _testAdUnitId : adUnitId;

    _bannerAd = BannerAd(
      adUnitId: targetUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _hasAdFailed = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('PremiumBannerAd failed to load ($targetUnitId): $error');
          ad.dispose();
          
          // If the production unit fails to load (e.g. Account not approved yet), 
          // transparently fallback to showing a test ad so the layout is still previewable/testable.
          if (!useFallback && targetUnitId == _productionAdUnitId) {
            if (mounted) {
              setState(() {
                _isAdLoaded = false;
                _hasAdFailed = false;
              });
              _loadBannerAd(useFallback: true);
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
      _bannerAd!.load();
    } catch (e) {
      debugPrint('Error loading PremiumBannerAd: $e');
      if (mounted) {
        setState(() {
          _hasAdFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenAdsEnabled = ref.watch(isAdEnabledForProvider(widget.screenName));
    final bannerFormatEnabled = ref.watch(isAdEnabledForProvider('banner'));
    final isAdAllowed = screenAdsEnabled && bannerFormatEnabled;

    if (!isAdAllowed) {
      if (_bannerAd != null) {
        _bannerAd!.dispose();
        _bannerAd = null;
        _isAdLoaded = false;
      }
      return const SizedBox.shrink();
    }

    // Trigger ad load asynchronously if it hasn't been initialized
    if (_bannerAd == null && !_hasAdFailed && !_isAdLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _bannerAd == null) {
          _loadBannerAd();
        }
      });
    }

    if (_hasAdFailed) {
      return const SizedBox.shrink(); // Hide ad slot cleanly if loading fails
    }

    final double adWidth = 320;
    final double adHeight = 50;

    return Center(
      child: GlassContainer(
        margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        width: adWidth + 24, // Wrap the ad nicely with some padding
        borderRadius: 16,
        borderColor: Colors.cyanAccent.withValues(alpha: 0.08),
        opacity: 0.05,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                'SPONSORED',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Container(
              width: adWidth,
              height: adHeight,
              alignment: Alignment.center,
              child: _isAdLoaded && _bannerAd != null
                  ? AdWidget(ad: _bannerAd!)
                  : _buildSkeletonLoader(adWidth, adHeight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.cyanAccent.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }
}
