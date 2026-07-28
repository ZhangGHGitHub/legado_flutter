import '../features/reader/reader_settings.dart';

/// 单主题槽排版（共用布局关闭时各槽独立；对齐 legado style configs 排版字段）
class ThemeTypography {
  final double fontSize;
  final double lineHeight;
  final String fontFamily;
  final ReaderFontWeight fontWeight;
  final double paddingHorizontal;
  final double paddingVertical;
  final double letterSpacing;
  final double paragraphSpacing;
  final int paragraphIndent;

  const ThemeTypography({
    this.fontSize = 18.0,
    this.lineHeight = 1.8,
    this.fontFamily = '',
    this.fontWeight = ReaderFontWeight.normal,
    this.paddingHorizontal = 20.0,
    this.paddingVertical = 8.0,
    this.letterSpacing = 0.0,
    this.paragraphSpacing = 0.2,
    this.paragraphIndent = 2,
  });

  factory ThemeTypography.fromReaderSettings(ReaderSettings s) {
    return ThemeTypography(
      fontSize: s.fontSize,
      lineHeight: s.lineHeight,
      fontFamily: s.fontFamily,
      fontWeight: s.fontWeight,
      paddingHorizontal: s.paddingHorizontal,
      paddingVertical: s.paddingVertical,
      letterSpacing: s.letterSpacing,
      paragraphSpacing: s.paragraphSpacing,
      paragraphIndent: s.paragraphIndent,
    );
  }

  ReaderSettings applyTo(ReaderSettings base) {
    return base.copyWith(
      fontSize: fontSize,
      lineHeight: lineHeight,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      paddingHorizontal: paddingHorizontal,
      paddingVertical: paddingVertical,
      letterSpacing: letterSpacing,
      paragraphSpacing: paragraphSpacing,
      paragraphIndent: paragraphIndent,
    );
  }

  ThemeTypography copyWith({
    double? fontSize,
    double? lineHeight,
    String? fontFamily,
    ReaderFontWeight? fontWeight,
    double? paddingHorizontal,
    double? paddingVertical,
    double? letterSpacing,
    double? paragraphSpacing,
    int? paragraphIndent,
  }) {
    return ThemeTypography(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      fontWeight: fontWeight ?? this.fontWeight,
      paddingHorizontal: paddingHorizontal ?? this.paddingHorizontal,
      paddingVertical: paddingVertical ?? this.paddingVertical,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      paragraphIndent: paragraphIndent ?? this.paragraphIndent,
    );
  }

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
      fontWeight:
          ReaderFontWeight.fromCode((json['fontWeight'] as num?)?.toInt() ?? 0),
      paddingHorizontal:
          (json['paddingHorizontal'] as num?)?.toDouble() ?? 20.0,
      paddingVertical: (json['paddingVertical'] as num?)?.toDouble() ?? 8.0,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      paragraphSpacing:
          (json['paragraphSpacing'] as num?)?.toDouble() ?? 0.2,
      paragraphIndent: (json['paragraphIndent'] as num?)?.toInt() ?? 2,
    );
  }
}
