import 'package:shared_preferences/shared_preferences.dart';

import 'bookshelf_prefs.dart';
import 'network_prefs.dart';
import 'web_api_prefs.dart';
import 'app_paths.dart';

/// 备份包中的 Flutter SharedPreferences 设置
abstract final class SettingsBackup {
  static const _settingKeys = [
    'legado_theme_mode',
    'legado_color_preset',
    'legado_theme_custom_colors',
    BookshelfPrefs.bookGroupStyleKey,
    BookshelfPrefs.bookshelfLayoutKey,
    BookshelfPrefs.bookshelfSortKey,
    BookshelfPrefs.showUnreadKey,
    BookshelfPrefs.showLastUpdateTimeKey,
    BookshelfPrefs.showWaitUpCountKey,
    BookshelfPrefs.showBookshelfFastScrollerKey,
    BookshelfPrefs.showBooknameKey,
    BookshelfPrefs.bookshelfMarginKey,
    WebApiPrefs.enabledKey,
    WebApiPrefs.portKey,
    WebApiPrefs.tokenKey,
    'webdav_url',
    'webdav_account',
    'webdav_password',
    'webdav_dir',
    'webdav_device',
    AppDataPrefs.dataDirKey,
    NetworkPrefs.enabledKey,
    NetworkPrefs.typeKey,
    NetworkPrefs.hostKey,
    NetworkPrefs.portKey,
    NetworkPrefs.userKey,
    NetworkPrefs.passKey,
    NetworkPrefs.dnsKey,
  ];

  static const _intKeys = {
    BookshelfPrefs.bookGroupStyleKey,
    BookshelfPrefs.bookshelfLayoutKey,
    BookshelfPrefs.bookshelfSortKey,
    BookshelfPrefs.showBooknameKey,
    BookshelfPrefs.bookshelfMarginKey,
    WebApiPrefs.portKey,
    NetworkPrefs.portKey,
  };

  static const _boolKeys = {
    WebApiPrefs.enabledKey,
    NetworkPrefs.enabledKey,
    BookshelfPrefs.showUnreadKey,
    BookshelfPrefs.showLastUpdateTimeKey,
    BookshelfPrefs.showWaitUpCountKey,
    BookshelfPrefs.showBookshelfFastScrollerKey,
  };

  static Future<Map<String, Object?>> collect() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <String, Object?>{};
    for (final key in _settingKeys) {
      if (!prefs.containsKey(key)) continue;
      if (_intKeys.contains(key)) {
        out[key] = prefs.getInt(key);
      } else if (_boolKeys.contains(key)) {
        out[key] = prefs.getBool(key);
      } else {
        out[key] = prefs.getString(key);
      }
    }
    return out;
  }

  static Future<void> apply(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in settings.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    }
  }
}
