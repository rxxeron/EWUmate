import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdManager {
  static String get _productionAdUnitId {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'ca-app-pub-7033696898787402/2396116121';
    }
    return '';
  }

  static String get _testAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test Interstitial ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test Interstitial ID
    }
    return '';
  }

  static String get adUnitId {
    if (kDebugMode) {
      return _testAdUnitId;
    }
    return _productionAdUnitId;
  }

  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;

  void loadAd({bool enabled = true}) {
    if (!enabled) {
      debugPrint('InterstitialAd load skipped (ads globally disabled).');
      return;
    }
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    if (_interstitialAd != null || _isAdLoading) return;

    _isAdLoading = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoading = false;
          debugPrint('InterstitialAd loaded successfully.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isAdLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  void showAd({required VoidCallback onAdDismissed, bool enabled = true}) {
    if (!enabled) {
      debugPrint('InterstitialAd show skipped (ads globally disabled).');
      onAdDismissed();
      return;
    }
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      onAdDismissed();
      return;
    }

    if (_interstitialAd != null) {
      _showLoadedAd(onAdDismissed);
      return;
    }

    // If the ad is not loaded yet but it is currently loading, wait up to 2.5 seconds
    if (_isAdLoading) {
      debugPrint('InterstitialAd is currently loading. Waiting for load to complete...');
      int elapsedMs = 0;
      const int checkIntervalMs = 150;
      const int maxWaitMs = 2500;

      Timer.periodic(const Duration(milliseconds: checkIntervalMs), (timer) {
        elapsedMs += checkIntervalMs;
        if (_interstitialAd != null) {
          timer.cancel();
          debugPrint('InterstitialAd loaded successfully during wait buffer. Showing ad.');
          _showLoadedAd(onAdDismissed);
        } else if (elapsedMs >= maxWaitMs || !_isAdLoading) {
          timer.cancel();
          debugPrint('InterstitialAd load wait buffer timed out or failed. Proceeding without ad.');
          onAdDismissed();
        }
      });
      return;
    }

    // If not loaded and not loading, try to load and proceed immediately
    debugPrint('Warning: InterstitialAd not ready and not loading. Proceeding with callback.');
    onAdDismissed();
    loadAd(enabled: enabled); // Try loading for next time with enabled flag
  }

  void _showLoadedAd(VoidCallback onAdDismissed) {
    Timer? failsafeTimer;
    bool hasProceeded = false;

    void proceed() {
      if (hasProceeded) return;
      hasProceeded = true;
      failsafeTimer?.cancel();
      onAdDismissed();
    }

    // Set a 5-second failsafe to invoke the callback if the ad freezes or SDK callbacks fail
    failsafeTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('Warning: InterstitialAd failsafe timer triggered. Invoking callback.');
      try {
        _interstitialAd?.dispose();
      } catch (e) {
        debugPrint('Error disposing ad in failsafe: $e');
      }
      _interstitialAd = null;
      proceed();
      loadAd();
    });

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('InterstitialAd dismissed.');
        ad.dispose();
        _interstitialAd = null;
        proceed();
        loadAd(); // Pre-load next ad
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('InterstitialAd failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        proceed();
        loadAd(); // Pre-load next ad
      },
    );

    try {
      _interstitialAd!.show();
    } catch (e) {
      debugPrint('Exception showing interstitial ad: $e. Proceeding with flow.');
      _interstitialAd = null;
      proceed();
      loadAd();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
