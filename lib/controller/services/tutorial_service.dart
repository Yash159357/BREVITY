import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const String _tutorialKey = 'tutorialShown';
  static const String _homeScreenTutorialKey = 'homeScreenTutorialShown';

  static Future<bool> shouldShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_tutorialKey) ?? false);
  }

  static Future<void> completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
  }

  // Home screen specific tutorial methods
  static Future<bool> shouldShowHomeScreenTutorial() async {
    return true;
    // final prefs = await SharedPreferences.getInstance();
    // return !(prefs.getBool(_homeScreenTutorialKey) ?? false);
  }

  static Future<void> completeHomeScreenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeScreenTutorialKey, true);
  }

  // Reset tutorial for testing purposes
  static Future<void> resetTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialKey);
    await prefs.remove(_homeScreenTutorialKey);
  }
}
