import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to enable/disable OS-level screenshot and screen recording blocking.
/// On Android, activates WindowManager.LayoutParams.FLAG_SECURE.
class ScreenProtectionService {
  static const MethodChannel _channel =
      MethodChannel('com.rxxeron.ewumate/screen_protection');

  static bool _isSecure = false;
  static bool get isSecure => _isSecure;

  /// Enables screenshot and screen recording blocking
  static Future<void> enableProtection() async {
    _isSecure = true;
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('enableSecure');
      debugPrint('[ScreenProtection] Screenshot & recording protection ENABLED.');
    } catch (e) {
      debugPrint('[ScreenProtection] Error enabling protection: $e');
    }
  }

  /// Disables screenshot and screen recording blocking (allows screenshots)
  static Future<void> disableProtection() async {
    _isSecure = false;
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('disableSecure');
      debugPrint('[ScreenProtection] Screenshot & recording protection DISABLED.');
    } catch (e) {
      debugPrint('[ScreenProtection] Error disabling protection: $e');
    }
  }
}
