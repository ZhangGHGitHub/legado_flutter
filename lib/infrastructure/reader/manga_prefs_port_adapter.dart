import '../../application/reader/manga_prefs_port.dart';
import '../../services/manga_prefs.dart' as service;

/// MangaPrefs 的应用端口适配器，保留旧 SharedPreferences 键和迁移语义。
final class MangaPrefsPortAdapter implements MangaPrefsPort {
  const MangaPrefsPortAdapter();

  @override
  Future<void> ensureLoaded() => service.MangaPrefs.ensureLoaded();

  @override
  MangaReadDirection get direction =>
      _fromServiceDirection(service.MangaPrefs.direction);

  @override
  bool get enableHorizontalScroll => service.MangaPrefs.enableHorizontalScroll;

  @override
  MangaColorFilterConfig get colorFilter =>
      _fromServiceFilter(service.MangaPrefs.colorFilter);

  @override
  MangaFooterConfig get footer => _fromServiceFooter(service.MangaPrefs.footer);

  @override
  bool get enableEInk => service.MangaPrefs.enableEInk;

  @override
  int get eInkThreshold => service.MangaPrefs.eInkThreshold;

  @override
  bool get enableGray => service.MangaPrefs.enableGray;

  @override
  bool get disableScale => service.MangaPrefs.disableScale;

  @override
  bool get disableClickScroll => service.MangaPrefs.disableClickScroll;

  @override
  int get preDownloadNum => service.MangaPrefs.preDownloadNum;

  @override
  bool get hideTitle => service.MangaPrefs.hideTitle;

  @override
  bool get disablePageAnim => service.MangaPrefs.disablePageAnim;

  @override
  bool get disableHorizontalPageSnap =>
      service.MangaPrefs.disableHorizontalPageSnap;

  @override
  int get autoPageSpeed => service.MangaPrefs.autoPageSpeed;

  @override
  Future<void> setDirection(MangaReadDirection value) =>
      service.MangaPrefs.setDirection(_toServiceDirection(value));

  @override
  Future<void> setHorizontalScroll(bool enabled) =>
      service.MangaPrefs.setHorizontalScroll(enabled);

  @override
  Future<void> setColorFilter(MangaColorFilterConfig value) =>
      service.MangaPrefs.setColorFilter(_toServiceFilter(value));

  @override
  Future<void> setFooter(MangaFooterConfig value) =>
      service.MangaPrefs.setFooter(_toServiceFooter(value));

  @override
  Future<void> setEInk({required bool enabled, int? threshold}) =>
      service.MangaPrefs.setEInk(enabled: enabled, threshold: threshold);

  @override
  Future<void> setGray(bool enabled) => service.MangaPrefs.setGray(enabled);

  @override
  Future<void> setDisableScale(bool value) =>
      service.MangaPrefs.setDisableScale(value);

  @override
  Future<void> setDisableClickScroll(bool value) =>
      service.MangaPrefs.setDisableClickScroll(value);

  @override
  Future<void> setPreDownloadNum(int value) =>
      service.MangaPrefs.setPreDownloadNum(value);

  @override
  Future<void> setHideTitle(bool value) =>
      service.MangaPrefs.setHideTitle(value);

  @override
  Future<void> setDisablePageAnim(bool value) =>
      service.MangaPrefs.setDisablePageAnim(value);

  @override
  Future<void> setDisableHorizontalPageSnap(bool value) =>
      service.MangaPrefs.setDisableHorizontalPageSnap(value);

  @override
  Future<void> setAutoPageSpeed(int value) =>
      service.MangaPrefs.setAutoPageSpeed(value);

  static MangaReadDirection _fromServiceDirection(
    service.MangaReadDirection value,
  ) {
    return MangaReadDirection.values[value.index.clamp(
      0,
      MangaReadDirection.values.length - 1,
    )];
  }

  static service.MangaReadDirection _toServiceDirection(
    MangaReadDirection value,
  ) {
    return service.MangaReadDirection.values[value.index.clamp(
      0,
      service.MangaReadDirection.values.length - 1,
    )];
  }

  static MangaColorFilterConfig _fromServiceFilter(
    service.MangaColorFilterConfig value,
  ) {
    return MangaColorFilterConfig(
      r: value.r,
      g: value.g,
      b: value.b,
      a: value.a,
      brightness: value.brightness,
    );
  }

  static service.MangaColorFilterConfig _toServiceFilter(
    MangaColorFilterConfig value,
  ) {
    return service.MangaColorFilterConfig(
      r: value.r,
      g: value.g,
      b: value.b,
      a: value.a,
      brightness: value.brightness,
    );
  }

  static MangaFooterConfig _fromServiceFooter(service.MangaFooterConfig value) {
    return MangaFooterConfig(
      hideFooter: value.hideFooter,
      hideChapterName: value.hideChapterName,
      hidePageNumber: value.hidePageNumber,
      hidePageNumberLabel: value.hidePageNumberLabel,
      hideChapter: value.hideChapter,
      hideChapterLabel: value.hideChapterLabel,
      hideProgressRatio: value.hideProgressRatio,
      hideProgressRatioLabel: value.hideProgressRatioLabel,
      footerOrientation: value.footerOrientation,
    );
  }

  static service.MangaFooterConfig _toServiceFooter(MangaFooterConfig value) {
    return service.MangaFooterConfig(
      hideFooter: value.hideFooter,
      hideChapterName: value.hideChapterName,
      hidePageNumber: value.hidePageNumber,
      hidePageNumberLabel: value.hidePageNumberLabel,
      hideChapter: value.hideChapter,
      hideChapterLabel: value.hideChapterLabel,
      hideProgressRatio: value.hideProgressRatio,
      hideProgressRatioLabel: value.hideProgressRatioLabel,
      footerOrientation: value.footerOrientation,
    );
  }
}
