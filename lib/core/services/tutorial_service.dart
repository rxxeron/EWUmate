import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  TutorialService._internal();

  static const String _keyPrefix = 'tutorial_seen_';

  /// Checks if a tutorial for a specific feature has been seen
  Future<bool> hasSeen(String feature) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyPrefix$feature') ?? false;
  }

  /// Marks a tutorial for a feature as seen
  Future<void> markAsSeen(String feature) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix$feature', true);
  }

  /// Resets all tutorials (for debugging)
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    for (var key in keys) {
      await prefs.remove(key);
    }
  }
}
