/// 阅读排版和主题色持久化配置，对齐 legado ReadBookConfig.Config 子集。
class ReadStyleConfig {
  const ReadStyleConfig({
    this.name = '',
    this.bgStr = '#EEEEEE',
    this.bgStrNight = '#000000',
    this.bgType = 0,
    this.bgTypeNight = 0,
    this.bgAlpha = 100,
    this.textColor = '#3E3D3B',
    this.textColorNight = '#ADADAD',
    this.textAccentColor = '#F44336',
    this.textAccentColorNight = '#F44336',
    this.textFont = '',
    this.textBold = 0,
    this.textSize = 20,
    this.letterSpacing = 0,
    this.lineSpacingExtra = 12,
    this.paragraphSpacing = 2,
    this.paddingLeft = 16,
    this.paddingRight = 16,
    this.paddingTop = 0,
    this.paddingBottom = 0,
    this.darkStatusIcon = true,
  });

  final String name;
  final String bgStr;
  final String bgStrNight;
  final int bgType;
  final int bgTypeNight;
  final int bgAlpha;
  final String textColor;
  final String textColorNight;
  final String textAccentColor;
  final String textAccentColorNight;
  final String textFont;
  final int textBold;
  final int textSize;
  final double letterSpacing;
  final int lineSpacingExtra;
  final int paragraphSpacing;
  final int paddingLeft;
  final int paddingRight;
  final int paddingTop;
  final int paddingBottom;
  final bool darkStatusIcon;

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

  ReadStyleConfig copyWith({
    String? name,
    String? bgStr,
    String? bgStrNight,
    int? bgType,
    int? bgTypeNight,
    int? bgAlpha,
    String? textColor,
    String? textColorNight,
    String? textAccentColor,
    String? textAccentColorNight,
    String? textFont,
    int? textBold,
    int? textSize,
    double? letterSpacing,
    int? lineSpacingExtra,
    int? paragraphSpacing,
    int? paddingLeft,
    int? paddingRight,
    int? paddingTop,
    int? paddingBottom,
    bool? darkStatusIcon,
  }) {
    return ReadStyleConfig(
      name: name ?? this.name,
      bgStr: bgStr ?? this.bgStr,
      bgStrNight: bgStrNight ?? this.bgStrNight,
      bgType: bgType ?? this.bgType,
      bgTypeNight: bgTypeNight ?? this.bgTypeNight,
      bgAlpha: bgAlpha ?? this.bgAlpha,
      textColor: textColor ?? this.textColor,
      textColorNight: textColorNight ?? this.textColorNight,
      textAccentColor: textAccentColor ?? this.textAccentColor,
      textAccentColorNight: textAccentColorNight ?? this.textAccentColorNight,
      textFont: textFont ?? this.textFont,
      textBold: textBold ?? this.textBold,
      textSize: textSize ?? this.textSize,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineSpacingExtra: lineSpacingExtra ?? this.lineSpacingExtra,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      paddingLeft: paddingLeft ?? this.paddingLeft,
      paddingRight: paddingRight ?? this.paddingRight,
      paddingTop: paddingTop ?? this.paddingTop,
      paddingBottom: paddingBottom ?? this.paddingBottom,
      darkStatusIcon: darkStatusIcon ?? this.darkStatusIcon,
    );
  }
}
