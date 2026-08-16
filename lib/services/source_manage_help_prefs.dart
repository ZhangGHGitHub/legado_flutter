import 'package:shared_preferences/shared_preferences.dart';

/// 书源管理帮助版本 gate — 对齐 Jingshiro LocalConfig / `book_sources_help_version`
abstract final class SourceManageHelpPrefs {
  static const currentVersion = 1;
  static const _key = 'book_sources_help_version';

  static Future<bool> shouldAutoShow() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getInt(_key) ?? 0;
    return seen < currentVersion;
  }

  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, currentVersion);
  }
}
