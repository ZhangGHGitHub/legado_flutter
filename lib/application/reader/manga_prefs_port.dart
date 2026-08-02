import 'package:freezed_annotation/freezed_annotation.dart';

part 'manga_prefs_port.freezed.dart';

/// 漫画阅读器偏好持久化边界。
abstract interface class MangaPrefsPort {
  Future<void> ensureLoaded();

  MangaReadDirection get direction;

  bool get enableHorizontalScroll;

  MangaColorFilterConfig get colorFilter;

  MangaFooterConfig get footer;

  bool get enableEInk;

  int get eInkThreshold;

  bool get enableGray;

  bool get disableScale;

  bool get disableClickScroll;

  int get preDownloadNum;

  bool get hideTitle;

  bool get disablePageAnim;

  bool get disableHorizontalPageSnap;

  int get autoPageSpeed;

  Future<void> setDirection(MangaReadDirection value);

  Future<void> setHorizontalScroll(bool enabled);

  Future<void> setColorFilter(MangaColorFilterConfig value);

  Future<void> setFooter(MangaFooterConfig value);

  Future<void> setEInk({required bool enabled, int? threshold});

  Future<void> setGray(bool enabled);

  Future<void> setDisableScale(bool value);

  Future<void> setDisableClickScroll(bool value);

  Future<void> setPreDownloadNum(int value);

  Future<void> setHideTitle(bool value);

  Future<void> setDisablePageAnim(bool value);

  Future<void> setDisableHorizontalPageSnap(bool value);

  Future<void> setAutoPageSpeed(int value);
}

/// 漫画阅读方向 — 上→下 / 左→右 / 右→左。
enum MangaReadDirection { vertical, leftToRight, rightToLeft }

/// 漫画阅读页脚显示配置。
@freezed
class MangaFooterConfig with _$MangaFooterConfig {
  const factory MangaFooterConfig({
    @Default(false) bool hideFooter,
    @Default(false) bool hideChapterName,
    @Default(false) bool hidePageNumber,
    @Default(false) bool hidePageNumberLabel,
    @Default(false) bool hideChapter,
    @Default(false) bool hideChapterLabel,
    @Default(false) bool hideProgressRatio,
    @Default(false) bool hideProgressRatioLabel,
    @Default(1) int footerOrientation,
  }) = _MangaFooterConfig;
}

/// 漫画图片滤镜配置。
@freezed
class MangaColorFilterConfig with _$MangaColorFilterConfig {
  const MangaColorFilterConfig._();

  const factory MangaColorFilterConfig({
    @Default(0) int r,
    @Default(0) int g,
    @Default(0) int b,
    @Default(0) int a,
    @Default(0) int brightness,
  }) = _MangaColorFilterConfig;

  bool get isIdentity =>
      r == 0 && g == 0 && b == 0 && a == 0 && brightness == 0;
}
