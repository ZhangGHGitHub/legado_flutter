import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/features/reader/reader_settings.dart';
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

  test(
    'renderedLineHeight measures base font metrics before applying ratio',
    () {
      const settings = ReaderSettings(fontSize: 18, lineHeight: 1.8);
      final rendered = ReaderFontLoader.renderedLineHeight(settings: settings);

      expect(rendered, isNotNull);
      expect(rendered, greaterThan(0));
      expect(rendered!.isFinite, isTrue);

      final style = ReaderFontLoader.contentTextStyle(
        settings: settings,
        color: const Color(0xFF000000),
        renderedLineHeight: rendered,
      );
      expect(style.height, closeTo(rendered / settings.fontSize, 1e-9));
    },
  );

  test('missing custom font falls back without registering a family', () async {
    final path = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}legado_missing_font.ttf',
    ).path;
    expect(await ReaderFontLoader.ensureLoaded(path), isNull);
    expect(
      ReaderFontLoader.resolveFamilySync(path),
      ReaderFontLoader.platformSansFamily(),
    );
    expect(
      await ReaderFontLoader.resolveFamily(path),
      ReaderFontLoader.platformSansFamily(),
    );
  });

  test('fallback chain keeps mixed Latin and CJK text measurable', () {
    const settings = ReaderSettings(fontSize: 18, lineHeight: 1.8);
    final style = ReaderFontLoader.contentTextStyle(
      settings: settings,
      color: Colors.black,
    );
    expect(style.fontFamilyFallback, contains('sans-serif'));

    final painter = TextPainter(
      text: TextSpan(text: 'A中文B', style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 240);
    final metrics = painter.computeLineMetrics();
    expect(metrics, isNotEmpty);
    expect(metrics.single.height.isFinite, isTrue);
    expect(metrics.single.height, greaterThan(0));
  });

  test('invalid line-height values use a finite style and no metric', () {
    for (final value in <double>[0, -1, double.nan, double.infinity]) {
      final settings = ReaderSettings(lineHeight: value);
      expect(ReaderFontLoader.renderedLineHeight(settings: settings), isNull);
      final style = ReaderFontLoader.contentTextStyle(
        settings: settings,
        color: Colors.black,
      );
      expect(style.height, 1.0);
    }
  });

  test('concurrent custom font loads share one pending operation', () async {
    final file = File(
      'reference${Platform.pathSeparator}Jingshiro-legado${Platform.pathSeparator}'
      'app${Platform.pathSeparator}src${Platform.pathSeparator}main${Platform.pathSeparator}'
      'assets${Platform.pathSeparator}font${Platform.pathSeparator}number.ttf',
    );
    expect(await file.exists(), isTrue);

    final results = await Future.wait([
      ReaderFontLoader.ensureLoaded(file.path),
      ReaderFontLoader.ensureLoaded(file.path),
      ReaderFontLoader.resolveFamily(file.path),
    ]);
    expect(results[0], isNotNull);
    expect(results[1], results[0]);
    expect(results[2], results[0]);
  });
}
