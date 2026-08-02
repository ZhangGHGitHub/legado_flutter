import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/reader/manga_prefs_port.dart';

void main() {
  group('MangaFooterConfig Freezed contract', () {
    test('keeps the original display defaults', () {
      const config = MangaFooterConfig();

      expect(config.hideFooter, isFalse);
      expect(config.hideChapterName, isFalse);
      expect(config.hidePageNumber, isFalse);
      expect(config.hidePageNumberLabel, isFalse);
      expect(config.hideChapter, isFalse);
      expect(config.hideChapterLabel, isFalse);
      expect(config.hideProgressRatio, isFalse);
      expect(config.hideProgressRatioLabel, isFalse);
      expect(config.footerOrientation, 1);
    });

    test('supports value equality and independent display changes', () {
      const original = MangaFooterConfig();
      const equivalent = MangaFooterConfig();
      final updated = original.copyWith(
        hideChapterName: true,
        footerOrientation: 2,
      );

      expect(original, equivalent);
      expect(updated.hideChapterName, isTrue);
      expect(updated.footerOrientation, 2);
      expect(updated.hideFooter, isFalse);
      expect(updated.hidePageNumber, isFalse);
    });
  });

  group('MangaColorFilterConfig Freezed contract', () {
    test('keeps the original identity defaults', () {
      const config = MangaColorFilterConfig();

      expect(config.r, 0);
      expect(config.g, 0);
      expect(config.b, 0);
      expect(config.a, 0);
      expect(config.brightness, 0);
      expect(config.isIdentity, isTrue);
    });

    test('retains filter values through copyWith and detects non-identity', () {
      const original = MangaColorFilterConfig(r: 8, g: 16);
      final updated = original.copyWith(a: 24, brightness: -12);

      expect(
        updated,
        const MangaColorFilterConfig(r: 8, g: 16, a: 24, brightness: -12),
      );
      expect(updated.isIdentity, isFalse);
      expect(original.a, 0);
      expect(original.brightness, 0);
    });
  });
}
