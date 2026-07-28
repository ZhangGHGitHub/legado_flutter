import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/read_style_config.dart';
import '../models/theme_typography.dart';
import '../features/reader/reader_settings.dart';
import 'bookshelf_prefs.dart';
import 'network_prefs.dart';
import 'read_book_config_prefs.dart';
import 'read_style_prefs.dart';
import 'web_api_prefs.dart';
import 'app_paths.dart';

/// Minimal storage boundary used by backup collection and restore.
abstract interface class SettingsStore {
  bool containsKey(String key);

  int? getInt(String key);

  bool? getBool(String key);

  String? getString(String key);

  Future<bool> setInt(String key, int value);

  Future<bool> setBool(String key, bool value);

  Future<bool> setString(String key, String value);

  Future<bool> setDouble(String key, double value);
}

/// Production adapter for the platform preferences implementation.
final class SharedPreferencesSettingsStore implements SettingsStore {
  const SharedPreferencesSettingsStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  bool containsKey(String key) => _prefs.containsKey(key);

  @override
  int? getInt(String key) => _prefs.getInt(key);

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  @override
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);
}

/// 备份包中的 Flutter SharedPreferences 设置
abstract final class SettingsBackup {
  static const readConfigFileName = 'readConfig.json';
  static const shareReadConfigFileName = 'shareReadConfig.json';
  static const legacyReadConfigKey = 'backup_legacy_read_config_json';
  static const legacyShareReadConfigKey =
      'backup_legacy_share_read_config_json';

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

  static Future<Map<String, Object?>> collect({SettingsStore? store}) async {
    final settings =
        store ??
        SharedPreferencesSettingsStore(await SharedPreferences.getInstance());
    final out = <String, Object?>{};
    for (final key in _settingKeys) {
      if (!settings.containsKey(key)) continue;
      if (_intKeys.contains(key)) {
        out[key] = settings.getInt(key);
      } else if (_boolKeys.contains(key)) {
        out[key] = settings.getBool(key);
      } else {
        out[key] = settings.getString(key);
      }
    }
    return out;
  }

  /// Export the two files used by the original app's [ReadBookConfig].
  ///
  /// The rewrite stores one active config plus optional per-theme typography,
  /// so the five-entry original array is represented by the four local theme
  /// slots plus the active shared config. Fields not represented by Flutter
  /// keep the original model defaults.
  static Future<Map<String, String>> collectLegacyReadConfigFiles() async {
    final current = await ReadBookConfigPrefs.load();
    final shareLayout = await ReadStylePrefs.loadShareLayout();
    final typography = await ReadStylePrefs.loadTypographyMap();
    final overrides = await ReadStylePrefs.loadOverrides();

    ReadStyleConfig configFor(String themeName, ThemeTypography type) {
      final base =
          ReaderTheme.themes[themeName] ?? ReaderTheme.themes['paper']!;
      final override = overrides[themeName];
      final background = override?.background ?? base.background;
      final text = override?.text ?? base.text;
      final accent = override?.accent ?? base.progress;
      return ReadStyleConfig(
        name: themeName,
        bgStr: ReadStyleConfig.toHex(background),
        textColor: ReadStyleConfig.toHex(text),
        textAccentColor: ReadStyleConfig.toHex(accent),
        textFont: type.fontFamily,
        textBold: type.fontWeight.code,
        textSize: type.fontSize.round(),
        letterSpacing: type.letterSpacing,
        lineSpacingExtra: ((type.lineHeight - 1.0) * type.fontSize).round(),
        paragraphSpacing: (type.paragraphSpacing * 10).round(),
        paddingLeft: type.paddingHorizontal.round(),
        paddingRight: type.paddingHorizontal.round(),
        paddingTop: type.paddingVertical.round(),
        paddingBottom: type.paddingVertical.round(),
      );
    }

    final shared = ThemeTypography.fromReaderSettings(current);
    final configs = [
      for (final (id, _) in ReaderTheme.themeSlots)
        configFor(id, shareLayout ? shared : (typography[id] ?? shared)),
      configFor(current.themeName, shared),
    ];
    return {
      readConfigFileName: jsonEncode(
        configs.map((config) => config.toJson()).toList(growable: false),
      ),
      shareReadConfigFileName: jsonEncode(configs.last.toJson()),
    };
  }

  static Future<void> apply(
    Map<String, dynamic> settings, {
    SettingsStore? store,
  }) async {
    final preferences =
        store ??
        SharedPreferencesSettingsStore(await SharedPreferences.getInstance());
    for (final entry in settings.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key == legacyReadConfigKey || key == legacyShareReadConfigKey) {
        if (value is String) {
          await _applyLegacyReadConfig(preferences, value);
        }
        continue;
      }
      if (value is int) {
        await preferences.setInt(key, value);
      } else if (value is bool) {
        await preferences.setBool(key, value);
      } else if (value is String) {
        await preferences.setString(key, value);
      } else if (value is double) {
        await preferences.setDouble(key, value);
      }
    }
  }

  static Future<void> _applyLegacyReadConfig(
    SettingsStore settings,
    String raw,
  ) async {
    try {
      final decoded = jsonDecode(raw);
      final map = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : decoded is List && decoded.isNotEmpty && decoded.first is Map
          ? Map<String, dynamic>.from(decoded.first as Map)
          : null;
      if (map == null) return;
      final current = await ReadBookConfigPrefs.load();
      final textSize = (map['textSize'] as num?)?.toDouble();
      final extra = (map['lineSpacingExtra'] as num?)?.toDouble();
      await ReadBookConfigPrefs.save(
        current.copyWith(
          fontSize: textSize,
          lineHeight: textSize == null || textSize <= 0 || extra == null
              ? null
              : (textSize + extra) / textSize,
          fontFamily: map['textFont']?.toString(),
          fontWeight: map['textBold'] is num
              ? ReaderFontWeight.fromCode((map['textBold'] as num).toInt())
              : null,
          letterSpacing: (map['letterSpacing'] as num?)?.toDouble(),
          paragraphSpacing:
              (map['paragraphSpacing'] as num?)?.toDouble() == null
              ? null
              : (map['paragraphSpacing'] as num).toDouble() / 10,
          paddingHorizontal: (map['paddingLeft'] as num?)?.toDouble(),
          paddingVertical: (map['paddingTop'] as num?)?.toDouble(),
        ),
      );
      await settings.setString(
        decoded is List ? legacyReadConfigKey : legacyShareReadConfigKey,
        raw,
      );
    } catch (_) {
      // Original Restore treats malformed optional config files as skippable.
    }
  }
}
