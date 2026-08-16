import 'package:freezed_annotation/freezed_annotation.dart';

part 'read_style_config.freezed.dart';

/// 阅读排版和主题色持久化配置，对齐 legado ReadBookConfig.Config 子集。
@freezed
class ReadStyleConfig with _$ReadStyleConfig {
  const ReadStyleConfig._();

  const factory ReadStyleConfig({
    @Default('') String name,
    @Default('#EEEEEE') String bgStr,
    @Default('#000000') String bgStrNight,
    @Default(0) int bgType,
    @Default(0) int bgTypeNight,
    @Default(100) int bgAlpha,
    @Default('#3E3D3B') String textColor,
    @Default('#ADADAD') String textColorNight,
    @Default('#F44336') String textAccentColor,
    @Default('#F44336') String textAccentColorNight,
    @Default('') String textFont,
    @Default(0) int textBold,
    @Default(20) int textSize,
    @Default(0) double letterSpacing,
    @Default(12) int lineSpacingExtra,
    @Default(2) int paragraphSpacing,
    @Default(16) int paddingLeft,
    @Default(16) int paddingRight,
    @Default(0) int paddingTop,
    @Default(0) int paddingBottom,
    @Default(true) bool darkStatusIcon,
  }) = _ReadStyleConfig;

  factory ReadStyleConfig.fromJson(Map<String, dynamic> json) {
    return ReadStyleConfig(
      name: json['name']?.toString() ?? '',
      bgStr: json['bgStr']?.toString() ?? '#EEEEEE',
      bgStrNight: json['bgStrNight']?.toString() ?? '#000000',
      bgType: (json['bgType'] as num?)?.toInt() ?? 0,
      bgTypeNight: (json['bgTypeNight'] as num?)?.toInt() ?? 0,
      bgAlpha: (json['bgAlpha'] as num?)?.toInt() ?? 100,
      textColor: json['textColor']?.toString() ?? '#3E3D3B',
      textColorNight: json['textColorNight']?.toString() ?? '#ADADAD',
      textAccentColor: json['textAccentColor']?.toString() ?? '#F44336',
      textAccentColorNight:
          json['textAccentColorNight']?.toString() ?? '#F44336',
      textFont: json['textFont']?.toString() ?? '',
      textBold: (json['textBold'] as num?)?.toInt() ?? 0,
      textSize: (json['textSize'] as num?)?.toInt() ?? 20,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0,
      lineSpacingExtra: (json['lineSpacingExtra'] as num?)?.toInt() ?? 12,
      paragraphSpacing: (json['paragraphSpacing'] as num?)?.toInt() ?? 2,
      paddingLeft: (json['paddingLeft'] as num?)?.toInt() ?? 16,
      paddingRight: (json['paddingRight'] as num?)?.toInt() ?? 16,
      paddingTop: (json['paddingTop'] as num?)?.toInt() ?? 0,
      paddingBottom: (json['paddingBottom'] as num?)?.toInt() ?? 0,
      darkStatusIcon: json['darkStatusIcon'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'bgStr': bgStr,
    'bgStrNight': bgStrNight,
    'bgType': bgType,
    'bgTypeNight': bgTypeNight,
    'bgAlpha': bgAlpha,
    'textColor': textColor,
    'textColorNight': textColorNight,
    'textAccentColor': textAccentColor,
    'textAccentColorNight': textAccentColorNight,
    'textFont': textFont,
    'textBold': textBold,
    'textSize': textSize,
    'letterSpacing': letterSpacing,
    'lineSpacingExtra': lineSpacingExtra,
    'paragraphSpacing': paragraphSpacing,
    'paddingLeft': paddingLeft,
    'paddingRight': paddingRight,
    'paddingTop': paddingTop,
    'paddingBottom': paddingBottom,
    'darkStatusIcon': darkStatusIcon,
  };
}
