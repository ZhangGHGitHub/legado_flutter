import 'package:freezed_annotation/freezed_annotation.dart';

import 'reader_font_weight.dart';

part 'theme_typography.freezed.dart';

/// 单主题槽排版值。
@freezed
class ThemeTypography with _$ThemeTypography {
  const ThemeTypography._();

  const factory ThemeTypography({
    @Default(18.0) double fontSize,
    @Default(1.8) double lineHeight,
    @Default('') String fontFamily,
    @Default(ReaderFontWeight.normal) ReaderFontWeight fontWeight,
    @Default(20.0) double paddingHorizontal,
    @Default(8.0) double paddingVertical,
    @Default(0.0) double letterSpacing,
    @Default(0.2) double paragraphSpacing,
    @Default(2) int paragraphIndent,
  }) = _ThemeTypography;

  Map<String, dynamic> toJson() => {
    'fontSize': fontSize,
    'lineHeight': lineHeight,
    'fontFamily': fontFamily,
    'fontWeight': fontWeight.code,
    'paddingHorizontal': paddingHorizontal,
    'paddingVertical': paddingVertical,
    'letterSpacing': letterSpacing,
    'paragraphSpacing': paragraphSpacing,
    'paragraphIndent': paragraphIndent,
  };

  factory ThemeTypography.fromJson(Map<String, dynamic> json) {
    return ThemeTypography(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.8,
      fontFamily: json['fontFamily']?.toString() ?? '',
      fontWeight: ReaderFontWeight.fromCode(
        (json['fontWeight'] as num?)?.toInt() ?? 0,
      ),
      paddingHorizontal:
          (json['paddingHorizontal'] as num?)?.toDouble() ?? 20.0,
      paddingVertical: (json['paddingVertical'] as num?)?.toDouble() ?? 8.0,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      paragraphSpacing: (json['paragraphSpacing'] as num?)?.toDouble() ?? 0.2,
      paragraphIndent: (json['paragraphIndent'] as num?)?.toInt() ?? 2,
    );
  }
}
