import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyMorningAlarm = 'pref_morning_alarm';

  /// Returns true if Morning Alarm is enabled (default: true)
  Future<bool> getMorningAlarmEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMorningAlarm) ?? true;
  }

  /// Updates the Morning Alarm preference
  Future<void> setMorningAlarmEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMorningAlarm, value);
  }
}
