# EWUMate: Ad Integration & UX Optimization Blueprint

This blueprint outlines a seamless, high-revenue, and UX-friendly approach to integrating ads into **EWUMate** using **Google Mobile Ads (AdMob)** in Flutter. 

Integrating ads into an utility app with a dark, premium, glassmorphic aesthetic requires careful styling and timing. If ads look like standard bright banners, they will shatter the premium vibe. By using **Native Ads** (which match your cards) and placing **Interstitial Ads** only during natural transition states (waiting for downloads or API generation), you can maximize revenue without hampering the user experience.

---

## 🗺️ Ad Placement & UX Strategy

Your proposed placements are highly strategic because they target **intent-rich, natural pausing points** in the user's workflow:

| Placement Spot | Suggested Ad Format | UX Strategy & Rationale |
| :--- | :--- | :--- |
| 🎛️ **App Services Screen** | **Native Inline Ad** | Replace a service card or place a dedicated card in the `GridView` that looks identical to other service tiles but is styled as "Sponsored". No layout shifts! |
| ⚡ **Advising: Combinations** | **Cloud-Wait Native Ad / Interstitial** | Since generation uses a background task, the user is staring at the "Optimizing Schedules" screen for a few seconds. Showing a Native Ad here fills the blank space. Once results are fully ready, show a subtle Interstitial. |
| 📄 **Cover Page Generator** | **Pre-loaded Interstitial Ad** | Tapping "Generate PDF" sends a POST request to Azure and waits 2-4 seconds. We can show an Interstitial Ad during this delay. Once dismissed, the PDF is immediately opened. |
| 📥 **Faculty List Download** | **Out-of-App Interstitial Ad** | Tapping the card triggers `launchUrl` (exiting the app to a browser). This is the *ideal* place for an Interstitial since the user is already transitioning out of the app. |
| 📍 **Banners Across Screens** | **Adaptive Anchor Banners** | Placed strictly at the bottom of the screens, pinned below any functional content (no overlapping buttons). |

---

## 🛠️ Phase 1: Dependency & Initialization

Add the Google Mobile Ads dependency to your `pubspec.yaml`:

```yaml
dependencies:
  google_mobile_ads: ^5.1.0  # Or the latest version
```

### Android Configuration (`android/app/src/main/AndroidManifest.xml`)
Add your AdMob App ID inside the `<application>` tag:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/> <!-- Replace with production ID -->
```

### iOS Configuration (`ios/Runner/Info.plist`)
Add the following keys to your iOS `Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string> <!-- Replace with production ID -->
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
</array>
```

---

## 🧱 Phase 2: Modular `AdService` Architecture

To prevent ad boilerplate from cluttering your screens, encapsulate all Google Mobile Ads logic into a clean, Riverpod-managed service at `lib/core/services/ad_service.dart`.

Create the file `lib/core/services/ad_service.dart`:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});

class AdService {
  // Test Ad Units (Replace with your production unit IDs from AdMob Console)
  String get bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  String get interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  String get nativeAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/2247696110'
      : 'ca-app-pub-3940256099942544/3986624511';

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoading = false;

  /// Initializes the Mobile Ads SDK
  Future<void> initialize() async {
    if (!kIsWeb) {
      await MobileAds.instance.initialize();
    }
  }

  /// Pre-loads an Interstitial Ad so it is ready to be shown instantly
  void loadInterstitialAd({VoidCallback? onAdLoaded}) {
    if (_isInterstitialAdLoading || _interstitialAd != null) return;

    _isInterstitialAdLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialAdLoading = false;
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  /// Shows the preloaded Interstitial Ad and fires a callback once dismissed
  void showInterstitialAd({
    required VoidCallback onAdDismissed,
  }) {
    if (_interstitialAd == null) {
      // If ad isn't loaded yet, immediately execute the transition callback so the user isn't stuck
      onAdDismissed();
      loadInterstitialAd(); // Attempt to reload for next time
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd(); // Pre-load the next one immediately
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onAdDismissed();
      },
    );

    _interstitialAd!.show();
  }

  /// Factory helper to build Native Ad options matching your glassmorphic style
  NativeAd loadNativeAd({
    required NativeAdListener listener,
    String? factoryId,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId: factoryId ?? 'listTile', // Needs corresponding native-side layout mapping
      listener: listener,
      request: const AdRequest(),
    );
  }
}
```

---

## 🎨 Phase 3: Screen Integrations & Blueprints

Here is exactly how to modify each of the screens you mentioned to support beautiful, non-disruptive ads.

### 🎛️ 1. App Services Screen (`lib/features/services/presentation/services_screen.dart`)
Instead of an annoying popup, we can dynamically add a **Native Card** inside the `GridView` or a clean banner at the very bottom of the screen.

```dart
// Suggested Layout update inside ServicesScreen build method:
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load a bottom anchor banner
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isBannerLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Academic Utilities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildServiceCard(context, title: 'Cover Page Generator', ...),
                        _buildServiceCard(context, title: 'Faculty List (PDF)', ...),
                        _buildServiceCard(context, title: 'Faculty Directory', ...),
                        // OPTION: We can inject a Native card here!
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Clean banner container at bottom - styled to match background!
          if (_isBannerLoaded && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}
```

---

### 📥 2. Faculty List Screen (`lib/features/services/presentation/faculty_list_screen.dart`)
Since tapping a faculty PDF launches a browser external application, show an **Interstitial Ad** right on tap.

```dart
// 1. Initialize and preload in initState
@override
void initState() {
  super.initState();
  // Pre-load the ad so it plays immediately on tap without buffering spinner
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(adServiceProvider).loadInterstitialAd();
  });
}

// 2. In the Card's onTap:
onTap: () {
  final adService = ref.read(adServiceProvider);
  
  // Show interstitial first, and open URL once it's dismissed or fails
  adService.showInterstitialAd(
    onAdDismissed: () {
      launchUrl(Uri.parse(s['url']), mode: LaunchMode.externalApplication);
    },
  );
}
```

---

### 📄 3. Cover Page Generator Screen (`lib/features/services/presentation/cover_page_screen.dart`)
Tapping **"Generate PDF"** takes 2-4 seconds to fetch from Azure. We can trigger an **Interstitial Ad** right when they submit, completely hiding the delay!

```dart
// 1. Preload the ad in initState
@override
void initState() {
  super.initState();
  _loadDepartments();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(adServiceProvider).loadInterstitialAd();
  });
}

// 2. Inside _generatePDF() method:
Future<void> _generatePDF(Map<String, dynamic> userProfile, String semester) async {
  if (!_formKey.currentState!.validate()) return;
  _formKey.currentState!.save();

  final adService = ref.read(adServiceProvider);
  
  // Trigger the ad. Once closed, run the PDF generation block
  adService.showInterstitialAd(
    onAdDismissed: () async {
      // ... existing PDF generation code ...
      final response = await http.post(
        Uri.parse('https://ewumate-parser.azurewebsites.net/api/generate_pdf'),
        // ...
      );
      // Open file...
    },
  );
}
```

---

### ⚡ 4. Advising Screen (`lib/features/advising/presentation/advising_screen.dart`)
During advising calculation, the user is locked waiting. We can show an inline **Native Ad** on the tracking screen.

```dart
Widget _buildGenerationOverview(String genId, ActiveSemester? activeSem) {
  final trackerAsync = ref.watch(generationTrackerProvider(genId));
  final semesterName = activeSem?.nextSemesterCode ?? 'Next Semester';

  return trackerAsync.when(
    data: (data) {
      if (data == null) return const Center(child: Text('Generation session missing.', style: TextStyle(color: Colors.white)));

      final status = data['status'] ?? 'processing';
      final count = data['count'] ?? 0;
      final combinations = data['combinations'] as List? ?? [];

      if (combinations.isNotEmpty) {
         return _buildResultsList(combinations, status, count, semesterName);
      }

      if (status == 'processing') {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.cyan),
              const SizedBox(height: 12),
              Text(
                'Doing advising for $semesterName',
                style: TextStyle(color: Colors.cyan[200], fontSize: 14),
              ),
              const SizedBox(height: 32),
              const Text(
                'Optimizing Schedules...',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'We have found $count combinations so far.',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              
              // 🌟 NATIVE AD INSERTION PLACEHOLDER
              // Show a beautiful card during the waiting period
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyan.withOpacity(0.2)),
                ),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.ads_click, color: Colors.cyan, size: 28),
                    SizedBox(height: 8),
                    Text(
                      'Sponsor/Ad Content',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'AdMob Native Ad loads here dynamically.',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              TextButton(
                onPressed: () => ref.read(advisingNotifierProvider.notifier).reset(),
                child: const Text('Cancel & Start Over', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
      }
      
      return _buildResultsList(combinations, status, count, semesterName);
    },
    ...
  );
}
```

---

## 🎨 Phase 4: Keeping UI/UX Premium (Styling Ads)

To ensure ads do not break your sleek dark-mode glassmorphic theme:

1. **Darken Ad Backgrounds**: When configuring **Native Ad templates** in AdMob console (or building custom native UI components in Android/iOS):
   - Set the ad container background to **Transparent** or a dark hex value like `#16202A` or `#1E2836`.
   - Set titles & description text colors to `#FFFFFF` and `#94A3B8` (grey).
   - Set primary buttons (Install, Visit) to a gorgeous gradient or solid `#00E5FF` (cyan) to match your buttons.
2. **Prevent Layout Shifting**: Always wrap your banner/native ads in widgets with **fixed constraints** (like a `SizedBox` or constrained container). If ads load late, the page will not suddenly jump up or down.
3. **Avoid Ads in Input/Forms**: Never place banner ads directly above or below input text fields. When the soft keyboard opens, it can squish the UI and result in accidental clicks, leading to policy violations from Google.
