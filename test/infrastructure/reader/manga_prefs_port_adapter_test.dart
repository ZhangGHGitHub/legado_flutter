import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/reader/manga_prefs_port.dart';
import 'package:legado_flutter/infrastructure/reader/manga_prefs_port_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const port = MangaPrefsPortAdapter();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'manga_read_direction_v1': 0,
      'manga_color_filter_v1': '',
      'manga_footer_config_v1': '',
      'manga_enable_eink_v1': false,
      'manga_eink_threshold_v1': 128,
      'manga_enable_gray_v1': false,
      'manga_disable_scale_v1': false,
      'manga_disable_click_scroll_v1': false,
      'manga_pre_download_num_v1': 10,
      'manga_hide_title_v1': false,
      'manga_disable_page_anim_v1': false,
      'manga_disable_h_page_snap_v1': false,
      'manga_auto_page_speed_v1': 3,
    });
    await port.ensureLoaded();
  });

  test('keeps the legacy defaults at the application boundary', () {
    expect(port.direction, MangaReadDirection.vertical);
    expect(port.enableHorizontalScroll, isFalse);
    expect(port.colorFilter.isIdentity, isTrue);
    expect(port.footer.footerOrientation, 1);
    expect(port.enableEInk, isFalse);
    expect(port.eInkThreshold, 128);
    expect(port.enableGray, isFalse);
    expect(port.disableScale, isFalse);
    expect(port.disableClickScroll, isFalse);
    expect(port.preDownloadNum, 10);
    expect(port.hideTitle, isFalse);
    expect(port.disablePageAnim, isFalse);
    expect(port.disableHorizontalPageSnap, isFalse);
    expect(port.autoPageSpeed, 3);
  });

  test(
    'preserves direction and horizontal-scroll persistence semantics',
    () async {
      final prefs = await SharedPreferences.getInstance();

      await port.setHorizontalScroll(true);
      expect(port.direction, MangaReadDirection.leftToRight);
      expect(prefs.getInt('manga_read_direction_v1'), 1);

      await port.setDirection(MangaReadDirection.rightToLeft);
      expect(port.enableHorizontalScroll, isTrue);
      expect(prefs.getInt('manga_read_direction_v1'), 2);

      await port.setHorizontalScroll(false);
      expect(port.direction, MangaReadDirection.vertical);
      expect(prefs.getInt('manga_read_direction_v1'), 0);
    },
  );

  test('preserves filter and footer mappings', () async {
    final prefs = await SharedPreferences.getInstance();
    const filter = MangaColorFilterConfig(
      r: 1,
      g: 2,
      b: 3,
      a: 4,
      brightness: 5,
    );
    const footer = MangaFooterConfig(
      hideFooter: true,
      hideChapterName: true,
      hidePageNumber: true,
      hidePageNumberLabel: true,
      hideChapter: true,
      hideChapterLabel: true,
      hideProgressRatio: true,
      hideProgressRatioLabel: true,
      footerOrientation: 0,
    );

    await port.setColorFilter(filter);
    expect(port.colorFilter.r, 1);
    expect(port.colorFilter.brightness, 5);
    expect(prefs.getString('manga_color_filter_v1'), isNotEmpty);

    await port.setColorFilter(const MangaColorFilterConfig());
    expect(port.colorFilter.isIdentity, isTrue);
    expect(prefs.getString('manga_color_filter_v1'), isEmpty);

    await port.setFooter(footer);
    expect(port.footer.hideFooter, isTrue);
    expect(port.footer.hideProgressRatioLabel, isTrue);
    expect(port.footer.footerOrientation, 0);
  });

  test('keeps clamping and eink/gray mutual exclusion', () async {
    final prefs = await SharedPreferences.getInstance();

    await port.setPreDownloadNum(999);
    await port.setAutoPageSpeed(0);
    expect(port.preDownloadNum, 50);
    expect(port.autoPageSpeed, 1);

    await port.setEInk(enabled: true, threshold: 999);
    expect(port.enableEInk, isTrue);
    expect(port.enableGray, isFalse);
    expect(port.eInkThreshold, 255);
    expect(prefs.getBool('manga_enable_gray_v1'), isFalse);

    await port.setGray(true);
    expect(port.enableGray, isTrue);
    expect(port.enableEInk, isFalse);
    expect(prefs.getBool('manga_enable_eink_v1'), isFalse);
  });
}
