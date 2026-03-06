import 'package:safe_device/safe_device.dart';

class JailbreakDetectionService {
  /// Returns true if the device is rooted or jail‑broken.
  Future<bool> isDeviceCompromised() async {
    try {
      return await SafeDevice.isJailBroken;
    } catch (e) {
      // If the plugin fails, assume safe default (not compromised)
      return false;
    }
  }
}
