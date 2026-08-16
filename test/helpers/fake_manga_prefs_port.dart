import 'package:legado_flutter/application/reader/manga_prefs_port.dart';

/// 漫画阅读器测试宿主的可控偏好端口。
final class FakeMangaPrefsPort implements MangaPrefsPort {
  FakeMangaPrefsPort({
    this.direction = MangaReadDirection.vertical,
    this.colorFilter = const MangaColorFilterConfig(),
    this.footer = const MangaFooterConfig(),
    this.enableEInk = false,
    this.eInkThreshold = 128,
    this.enableGray = false,
    this.disableScale = false,
    this.disableClickScroll = false,
    this.preDownloadNum = 10,
    this.hideTitle = false,
    this.disablePageAnim = false,
    this.disableHorizontalPageSnap = false,
    this.autoPageSpeed = 3,
  });

  @override
  MangaReadDirection direction;

  @override
  MangaColorFilterConfig colorFilter;

  @override
  MangaFooterConfig footer;

  @override
  bool enableEInk;

  @override
  int eInkThreshold;

  @override
  bool enableGray;

  @override
  bool disableScale;

  @override
  bool disableClickScroll;

  @override
  int preDownloadNum;

  @override
  bool hideTitle;

  @override
  bool disablePageAnim;

  @override
  bool disableHorizontalPageSnap;

  @override
  int autoPageSpeed;

  @override
  bool get enableHorizontalScroll => direction != MangaReadDirection.vertical;

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setDirection(MangaReadDirection value) async =>
      direction = value;

  @override
  Future<void> setHorizontalScroll(bool enabled) async {
    direction = enabled
        ? MangaReadDirection.leftToRight
        : MangaReadDirection.vertical;
  }

  @override
  Future<void> setColorFilter(MangaColorFilterConfig value) async =>
      colorFilter = value;

  @override
  Future<void> setFooter(MangaFooterConfig value) async => footer = value;

  @override
  Future<void> setEInk({required bool enabled, int? threshold}) async {
    enableEInk = enabled;
    if (enabled) enableGray = false;
    if (threshold != null) eInkThreshold = threshold.clamp(0, 255);
  }

  @override
  Future<void> setGray(bool enabled) async {
    enableGray = enabled;
    if (enabled) enableEInk = false;
  }

  @override
  Future<void> setDisableScale(bool value) async => disableScale = value;

  @override
  Future<void> setDisableClickScroll(bool value) async =>
      disableClickScroll = value;

  @override
  Future<void> setPreDownloadNum(int value) async =>
      preDownloadNum = value.clamp(0, 50);

  @override
  Future<void> setHideTitle(bool value) async => hideTitle = value;

  @override
  Future<void> setDisablePageAnim(bool value) async => disablePageAnim = value;

  @override
  Future<void> setDisableHorizontalPageSnap(bool value) async =>
      disableHorizontalPageSnap = value;

  @override
  Future<void> setAutoPageSpeed(int value) async =>
      autoPageSpeed = value.clamp(1, 20);
}
