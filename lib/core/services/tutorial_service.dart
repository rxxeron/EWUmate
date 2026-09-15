import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const String _prefix = 'tutorial_';

  Future<bool> hasSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$key') ?? false;
  }

  Future<void> markAsSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', true);
  }

  Future<bool> hasCompletedWelcomeTour() async {
    return hasSeen('welcome_tour_v1');
  }

  /// Reset all tutorial keys — useful for testing or "Replay Tour"
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Reset only the welcome tour so it replays on next login
  Future<void> resetWelcomeTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_prefix}welcome_tour_v1');
  }
}

