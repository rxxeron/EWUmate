import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  /// Checks Google Play Store directly for updates.
  /// Uses Flexible update for normal updates (downloads in background without disruption).
  /// Uses Immediate update if high priority is specified in Google Play Developer Console.
  static Future<void> checkForPlayStoreUpdate() async {
    // In-app updates only function on Android devices installed via Play Store
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android || kDebugMode) {
      return;
    }

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // High priority updates (>= 4) prompt Immediate full-screen blocking update
        if (updateInfo.updatePriority >= 4 && updateInfo.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } 
        // Regular updates trigger smooth background flexible update
        else if (updateInfo.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Play Store update check failed: ');
    }
  }
}
