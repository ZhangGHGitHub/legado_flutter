import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../pages/reader/reader_settings.dart';

/// 全局阅读配置持久化 — 对齐 Jingshiro [ReadBookConfig]
///（`filesDir/readConfig.json` + `shareReadConfig.json`，面板关闭时 `save()`）。
///
/// Flutter 用 SharedPreferences JSON；主题槽覆盖仍走 [ReadStylePrefs]。
abstract final class ReadBookConfigPrefs {
  static const _kConfig = 'read_book_config_v1';

  /// 从磁盘合并到 [base]（对齐 `ReadBookConfig.initConfigs`）。
  static Future<ReaderSettings> load({
    ReaderSettings base = const ReaderSettings(),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kConfig);
    if (raw == null || raw.isEmpty) return base;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return base;
      return _fromJson(Map<String, dynamic>.from(map), base);
    } catch (_) {
      return base;
    }
  }

  /// 对齐 `ReadBookConfig.save()`：异步落盘全局排版 + 翻页动画等。
  static Future<void> save(ReaderSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kConfig, jsonEncode(_toJson(s)));
  }

  static Map<String, dynamic> _toJson(ReaderSettings s) => {
        'pageMode': s.pageMode,
        'fontSize': s.fontSize,
        'lineHeight': s.lineHeight,
        'fontFamily': s.fontFamily,
        'paddingHorizontal': s.paddingHorizontal,
        'paddingVertical': s.paddingVertical,
        'showTime': s.showTime,
        'showBattery': s.showBattery,
        'showPageInfo': s.showPageInfo,
        'volumeKeyTurnPage': s.volumeKeyTurnPage,
        'volumeKeyPageOnPlay': s.volumeKeyPageOnPlay,
        'autoReadIntervalSec': s.autoReadIntervalSec,
        'screenOrientation': s.screenOrientation.name,
        'brightnessFollowSystem': s.brightnessFollowSystem,
        'brightness': s.brightness,
        'screenTimeout': s.screenTimeout.name,
        'bluetoothPageKey': s.bluetoothPageKey,
        'customPrevPageKey': s.customPrevPageKey,
        'customNextPageKey': s.customNextPageKey,
        'fontWeight': s.fontWeight.code,
        'paragraphIndent': s.paragraphIndent,
        'letterSpacing': s.letterSpacing,
        'paragraphSpacing': s.paragraphSpacing,
        'chineseConvert': s.chineseConvert.name,
        'hideStatusBar': s.hideStatusBar,
        'hideNavigationBar': s.hideNavigationBar,
        'expandIntoCutout': s.expandIntoCutout,
        'textFullJustify': s.textFullJustify,
        'textBottomJustify': s.textBottomJustify,
        // 九宫格另有 ClickActionPrefs；此处双写便于单文件备份对齐 readConfig。
        'clickTL': s.clickTL.name,
        'clickTC': s.clickTC.name,
        'clickTR': s.clickTR.name,
        'clickML': s.clickML.name,
        'clickMC': s.clickMC.name,
        'clickMR': s.clickMR.name,
        'clickBL': s.clickBL.name,
        'clickBC': s.clickBC.name,
        'clickBR': s.clickBR.name,
      };

  static ReaderSettings _fromJson(Map<String, dynamic> json, ReaderSettings base) {
    T enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
      if (raw is! String) return fallback;
      for (final v in values) {
        if (v.name == raw) return v;
      }
      return fallback;
    }

    ClickZoneAction click(Object? raw, ClickZoneAction fallback) =>
        enumByName(ClickZoneAction.values, raw, fallback);

    return base.copyWith(
      pageMode: json['pageMode']?.toString() ?? base.pageMode,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? base.fontSize,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? base.lineHeight,
      fontFamily: json['fontFamily']?.toString() ?? base.fontFamily,
      paddingHorizontal:
          (json['paddingHorizontal'] as num?)?.toDouble() ?? base.paddingHorizontal,
      paddingVertical:
          (json['paddingVertical'] as num?)?.toDouble() ?? base.paddingVertical,
      showTime: json['showTime'] as bool? ?? base.showTime,
      showBattery: json['showBattery'] as bool? ?? base.showBattery,
      showPageInfo: json['showPageInfo'] as bool? ?? base.showPageInfo,
      volumeKeyTurnPage:
          json['volumeKeyTurnPage'] as bool? ?? base.volumeKeyTurnPage,
      volumeKeyPageOnPlay:
          json['volumeKeyPageOnPlay'] as bool? ?? base.volumeKeyPageOnPlay,
      autoReadIntervalSec: (json['autoReadIntervalSec'] as num?)?.toDouble() ??
          base.autoReadIntervalSec,
      screenOrientation: enumByName(
        ScreenOrientationMode.values,
        json['screenOrientation'],
        base.screenOrientation,
      ),
      brightnessFollowSystem:
          json['brightnessFollowSystem'] as bool? ?? base.brightnessFollowSystem,
      brightness: (json['brightness'] as num?)?.toDouble() ?? base.brightness,
      screenTimeout: enumByName(
        ScreenTimeoutMode.values,
        json['screenTimeout'],
        base.screenTimeout,
      ),
      bluetoothPageKey:
          json['bluetoothPageKey'] as bool? ?? base.bluetoothPageKey,
      customPrevPageKey: json['customPrevPageKey']?.toString(),
      customNextPageKey: json['customNextPageKey']?.toString(),
      fontWeight: ReaderFontWeight.fromCode(
        (json['fontWeight'] as num?)?.toInt() ?? base.fontWeight.code,
      ),
      paragraphIndent:
          (json['paragraphIndent'] as num?)?.toInt() ?? base.paragraphIndent,
      letterSpacing:
          (json['letterSpacing'] as num?)?.toDouble() ?? base.letterSpacing,
      paragraphSpacing:
          (json['paragraphSpacing'] as num?)?.toDouble() ?? base.paragraphSpacing,
      chineseConvert: enumByName(
        ChineseConvertMode.values,
        json['chineseConvert'],
        base.chineseConvert,
      ),
      hideStatusBar: json['hideStatusBar'] as bool? ?? base.hideStatusBar,
      hideNavigationBar:
          json['hideNavigationBar'] as bool? ?? base.hideNavigationBar,
      expandIntoCutout:
          json['expandIntoCutout'] as bool? ?? base.expandIntoCutout,
      textFullJustify: json['textFullJustify'] as bool? ?? base.textFullJustify,
      textBottomJustify:
          json['textBottomJustify'] as bool? ?? base.textBottomJustify,
      clickTL: click(json['clickTL'], base.clickTL),
      clickTC: click(json['clickTC'], base.clickTC),
      clickTR: click(json['clickTR'], base.clickTR),
      clickML: click(json['clickML'], base.clickML),
      clickMC: click(json['clickMC'], base.clickMC),
      clickMR: click(json['clickMR'], base.clickMR),
      clickBL: click(json['clickBL'], base.clickBL),
      clickBC: click(json['clickBC'], base.clickBC),
      clickBR: click(json['clickBR'], base.clickBR),
    );
  }
}
