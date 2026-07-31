import 'dart:io';

import 'package:flutter/material.dart';

import '../../features/reader/reader_settings.dart';

/// 阅读器字体选择、预览与自定义字体加载所需的应用能力。
abstract interface class ReaderFontPort {
  String platformSansFamily();

  String platformSerifFamily();

  String platformMonoFamily();

  List<String> cjkFallbackFamilies();

  bool isFontFilePath(String value);

  String displayName(String fontFamily);

  String resolveFamilySync(String fontFamily);

  Future<String?> ensureLoaded(String fontPath);

  Future<String> resolveFamily(String fontFamily);

  Future<Directory> fontDirectory();

  Future<List<File>> listCustomFontFiles();

  TextStyle contentTextStyle({
    required ReaderSettings settings,
    required Color color,
    String? resolvedFamily,
    double? renderedLineHeight,
  });

  double? renderedLineHeight({
    required ReaderSettings settings,
    String? resolvedFamily,
  });
}
