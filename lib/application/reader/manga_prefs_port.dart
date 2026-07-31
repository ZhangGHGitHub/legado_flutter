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
class MangaFooterConfig {
  final bool hideFooter;
  final bool hideChapterName;
  final bool hidePageNumber;
  final bool hidePageNumberLabel;
  final bool hideChapter;
  final bool hideChapterLabel;
  final bool hideProgressRatio;
  final bool hideProgressRatioLabel;
  final int footerOrientation;

  const MangaFooterConfig({
    this.hideFooter = false,
    this.hideChapterName = false,
    this.hidePageNumber = false,
    this.hidePageNumberLabel = false,
    this.hideChapter = false,
    this.hideChapterLabel = false,
    this.hideProgressRatio = false,
    this.hideProgressRatioLabel = false,
    this.footerOrientation = 1,
  });

  MangaFooterConfig copyWith({
    bool? hideFooter,
    bool? hideChapterName,
    bool? hidePageNumber,
    bool? hidePageNumberLabel,
    bool? hideChapter,
    bool? hideChapterLabel,
    bool? hideProgressRatio,
    bool? hideProgressRatioLabel,
    int? footerOrientation,
  }) {
    return MangaFooterConfig(
      hideFooter: hideFooter ?? this.hideFooter,
      hideChapterName: hideChapterName ?? this.hideChapterName,
      hidePageNumber: hidePageNumber ?? this.hidePageNumber,
      hidePageNumberLabel: hidePageNumberLabel ?? this.hidePageNumberLabel,
      hideChapter: hideChapter ?? this.hideChapter,
      hideChapterLabel: hideChapterLabel ?? this.hideChapterLabel,
      hideProgressRatio: hideProgressRatio ?? this.hideProgressRatio,
      hideProgressRatioLabel:
          hideProgressRatioLabel ?? this.hideProgressRatioLabel,
      footerOrientation: footerOrientation ?? this.footerOrientation,
    );
  }
}

/// 漫画图片滤镜配置。
class MangaColorFilterConfig {
  final int r;
  final int g;
  final int b;
  final int a;
  final int brightness;

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
}
