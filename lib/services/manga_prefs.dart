import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 漫画阅读方向 — 对齐 UI-23：上→下 / 左→右 / 右→左
enum MangaReadDirection {
  vertical,
  leftToRight,
  rightToLeft,
}

extension MangaReadDirectionX on MangaReadDirection {
  String get label => switch (this) {
        MangaReadDirection.vertical => '上→下',
        MangaReadDirection.leftToRight => '左→右',
        MangaReadDirection.rightToLeft => '右→左',
      };

  MangaReadDirection get next => MangaReadDirection
      .values[(index + 1) % MangaReadDirection.values.length];
}

/// 颜色滤镜 — 对齐 `MangaColorFilterConfig` / `dialog_manga_color_filter.xml`
class MangaColorFilterConfig {
  final int r;
  final int g;
  final int b;
  final int a;
  final int brightness; // legado `l`，0–255

  const MangaColorFilterConfig({
    this.r = 0,
    this.g = 0,
    this.b = 0,
    this.a = 0,
    this.brightness = 0,
  });

  bool get isIdentity =>
      r == 0 && g == 0 && b == 0 && a == 0 && brightness == 0;

  MangaColorFilterConfig copyWith({
    int? r,
    int? g,
    int? b,
    int? a,
    int? brightness,
  }) {
    return MangaColorFilterConfig(
      r: r ?? this.r,
      g: g ?? this.g,
      b: b ?? this.b,
      a: a ?? this.a,
      brightness: brightness ?? this.brightness,
    );
  }

  Map<String, dynamic> toJson() => {
        'r': r,
        'g': g,
        'b': b,
        'a': a,
        'l': brightness,
      };

  factory MangaColorFilterConfig.fromJson(Map<String, dynamic> json) {
    return MangaColorFilterConfig(
      r: (json['r'] as num?)?.toInt() ?? 0,
      g: (json['g'] as num?)?.toInt() ?? 0,
      b: (json['b'] as num?)?.toInt() ?? 0,
      a: (json['a'] as num?)?.toInt() ?? 0,
      brightness: (json['l'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 漫画阅读器偏好 — SharedPreferences，对齐 Jingshiro AppConfig 漫画项
class MangaPrefs {
  MangaPrefs._();

  static const _kDirection = 'manga_read_direction_v1';
  static const _kFilter = 'manga_color_filter_v1';
  static const _kEInk = 'manga_enable_eink_v1';
  static const _kEInkThreshold = 'manga_eink_threshold_v1';
  static const _kGray = 'manga_enable_gray_v1';
  static const _kDisableScale = 'manga_disable_scale_v1';
  static const _kDisableClickScroll = 'manga_disable_click_scroll_v1';
  static const _kPreDownload = 'manga_pre_download_num_v1';
  static const _kHideTitle = 'manga_hide_title_v1';

  static MangaReadDirection direction = MangaReadDirection.vertical;
  static MangaColorFilterConfig colorFilter = const MangaColorFilterConfig();
  static bool enableEInk = false;
  static int eInkThreshold = 128;
  static bool enableGray = false;
  static bool disableScale = false;
  static bool disableClickScroll = false;
  static int preDownloadNum = 10;
  static bool hideTitle = false;

  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final dirIdx = p.getInt(_kDirection) ?? 0;
    direction = MangaReadDirection.values[
        dirIdx.clamp(0, MangaReadDirection.values.length - 1)];
    final filterRaw = p.getString(_kFilter);
    if (filterRaw != null && filterRaw.isNotEmpty) {
      try {
        colorFilter = MangaColorFilterConfig.fromJson(
          Map<String, dynamic>.from(jsonDecode(filterRaw) as Map),
        );
      } catch (_) {
        colorFilter = const MangaColorFilterConfig();
      }
    }
    enableEInk = p.getBool(_kEInk) ?? false;
    eInkThreshold = (p.getInt(_kEInkThreshold) ?? 128).clamp(0, 255);
    enableGray = p.getBool(_kGray) ?? false;
    disableScale = p.getBool(_kDisableScale) ?? false;
    disableClickScroll = p.getBool(_kDisableClickScroll) ?? false;
    preDownloadNum = (p.getInt(_kPreDownload) ?? 10).clamp(0, 50);
    hideTitle = p.getBool(_kHideTitle) ?? false;
    _loaded = true;
  }

  static Future<void> setDirection(MangaReadDirection value) async {
    direction = value;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kDirection, value.index);
  }

  static Future<void> setColorFilter(MangaColorFilterConfig value) async {
    colorFilter = value;
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kFilter,
      value.isIdentity ? '' : jsonEncode(value.toJson()),
    );
  }

  static Future<void> setEInk({required bool enabled, int? threshold}) async {
    enableEInk = enabled;
    if (enabled) enableGray = false;
    if (threshold != null) eInkThreshold = threshold.clamp(0, 255);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEInk, enableEInk);
    await p.setBool(_kGray, enableGray);
    await p.setInt(_kEInkThreshold, eInkThreshold);
  }

  static Future<void> setGray(bool enabled) async {
    enableGray = enabled;
    if (enabled) enableEInk = false;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kGray, enableGray);
    await p.setBool(_kEInk, enableEInk);
  }

  static Future<void> setDisableScale(bool value) async {
    disableScale = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDisableScale, value);
  }

  static Future<void> setDisableClickScroll(bool value) async {
    disableClickScroll = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDisableClickScroll, value);
  }

  static Future<void> setPreDownloadNum(int value) async {
    preDownloadNum = value.clamp(0, 50);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kPreDownload, preDownloadNum);
  }

  static Future<void> setHideTitle(bool value) async {
    hideTitle = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kHideTitle, value);
  }

  /// 书源类型是否为图片/漫画（`BookSourceType.image == 2`）
  static bool isImageSourceType(String? bookSourceType) {
    if (bookSourceType == null) return false;
    final t = bookSourceType.trim().toLowerCase();
    return t == '2' || t == 'image' || t == '漫画' || t == '图片';
  }
}
