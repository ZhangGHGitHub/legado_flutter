import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/reader/reader_settings.dart';
import 'package:legado_flutter/services/reader_font_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('system default resolves to a concrete platform sans family', () {
    final family = ReaderFontLoader.resolveFamilySync('');
    expect(family, isNotEmpty);
    expect(family, isNot(equals('')));
    // Windows CI/dev: Microsoft YaHei; others: platform sans.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      expect(family, 'Microsoft YaHei');
    }
  });

  test('serif/mono map like Jingshiro Typeface.SERIF/MONOSPACE', () {
    expect(ReaderFontLoader.resolveFamilySync('serif'), isNotEmpty);
    expect(ReaderFontLoader.resolveFamilySync('monospace'), isNotEmpty);
  });

  test('contentTextStyle sets family + CJK fallbacks', () {
    const s = ReaderSettings(fontSize: 18, fontFamily: '');
    final style = ReaderFontLoader.contentTextStyle(
      settings: s,
      color: const Color(0xFF000000),
    );
    expect(style.fontFamily, isNotNull);
    expect(style.fontFamilyFallback, isNotEmpty);
    expect(style.fontWeight, FontWeight.w400);
  });
}
