import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  Future<bool> hasSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tutorial_$key') ?? false;
  }

  Future<void> markAsSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_$key', true);
  }
}
