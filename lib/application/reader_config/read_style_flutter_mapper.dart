import 'package:flutter/material.dart';

import '../../domain/reader_config/read_style_config.dart';

abstract final class ReadStyleColorMapper {
  static Color? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var value = raw.trim();
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return null;
    final argb = int.tryParse(value, radix: 16);
    return argb == null ? null : Color(argb);
  }

  static String toHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

extension ReadStyleConfigColors on ReadStyleConfig {
  Color? get dayBgColor =>
      bgType == 0 ? ReadStyleColorMapper.parse(bgStr) : null;
  Color? get nightBgColor =>
      bgTypeNight == 0 ? ReadStyleColorMapper.parse(bgStrNight) : null;
  Color? get dayTextColor => ReadStyleColorMapper.parse(textColor);
  Color? get nightTextColor => ReadStyleColorMapper.parse(textColorNight);
  Color? get dayAccentColor => ReadStyleColorMapper.parse(textAccentColor);
  Color? get nightAccentColor =>
      ReadStyleColorMapper.parse(textAccentColorNight);
}

/// 阅读主题槽位的本地 Flutter 覆盖，图片路径另存。
class ReadStyleSlotOverride {
  const ReadStyleSlotOverride({
    this.name,
    this.background,
    this.text,
    this.accent,
    this.bgImagePath,
    this.darkStatusIcon = true,
  });

  final String? name;
  final Color? background;
  final Color? text;
  final Color? accent;
  final String? bgImagePath;
  final bool darkStatusIcon;

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (background != null)
      'background': ReadStyleColorMapper.toHex(background!),
    if (text != null) 'text': ReadStyleColorMapper.toHex(text!),
    if (accent != null) 'accent': ReadStyleColorMapper.toHex(accent!),
    if (bgImagePath != null && bgImagePath!.isNotEmpty)
      'bgImagePath': bgImagePath,
    'darkStatusIcon': darkStatusIcon,
  };

  factory ReadStyleSlotOverride.fromJson(Map<String, dynamic> json) {
    return ReadStyleSlotOverride(
      name: json['name']?.toString(),
      background: ReadStyleColorMapper.parse(json['background']?.toString()),
      text: ReadStyleColorMapper.parse(json['text']?.toString()),
      accent: ReadStyleColorMapper.parse(json['accent']?.toString()),
      bgImagePath: json['bgImagePath']?.toString(),
      darkStatusIcon: json['darkStatusIcon'] as bool? ?? true,
    );
  }

  ReadStyleSlotOverride copyWith({
    String? name,
    Color? background,
    Color? text,
    Color? accent,
    String? bgImagePath,
    bool? darkStatusIcon,
    bool clearBgImage = false,
  }) {
    return ReadStyleSlotOverride(
      name: name ?? this.name,
      background: background ?? this.background,
      text: text ?? this.text,
      accent: accent ?? this.accent,
      bgImagePath: clearBgImage ? null : (bgImagePath ?? this.bgImagePath),
      darkStatusIcon: darkStatusIcon ?? this.darkStatusIcon,
    );
  }
}
