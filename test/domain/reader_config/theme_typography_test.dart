import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/reader_config/reader_font_weight.dart';
import 'package:legado_flutter/domain/reader_config/theme_typography.dart';

void main() {
  test('ThemeTypography keeps defaults and copyWith value semantics', () {
    const typography = ThemeTypography();

    expect(typography.fontSize, 18.0);
    expect(typography.lineHeight, 1.8);
    expect(typography.fontWeight, ReaderFontWeight.normal);
    expect(typography, equals(typography.copyWith()));
    expect(typography.copyWith(fontSize: 20).fontSize, 20);
  });

  test('ThemeTypography preserves font weight code in JSON', () {
    final typography = ThemeTypography.fromJson({
      'fontSize': 19,
      'fontWeight': 1,
      'paragraphIndent': 3,
    });

    expect(typography.fontWeight, ReaderFontWeight.bold);
    expect(typography.paragraphIndent, 3);
    expect(typography.toJson()['fontWeight'], 1);
  });
}
