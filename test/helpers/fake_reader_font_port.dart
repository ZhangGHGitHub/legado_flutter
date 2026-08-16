import 'dart:io';

import 'package:flutter/material.dart';
import 'package:legado_flutter/application/reader/reader_font_port.dart';
import 'package:legado_flutter/features/reader/reader_settings.dart';

/// 测试宿主的默认字体端口，具体测试可覆盖需要断言的字体族。
abstract class FakeReaderFontPort implements ReaderFontPort {
  const FakeReaderFontPort();

  @override
  String platformSansFamily() => 'TestSans';

  @override
  String platformSerifFamily() => 'TestSerif';

  @override
  String platformMonoFamily() => 'TestMono';

  @override
  List<String> cjkFallbackFamilies() => const ['TestCjk', 'sans-serif'];

  @override
  bool isFontFilePath(String value) => false;

  @override
  String displayName(String fontFamily) => fontFamily;

  @override
  String resolveFamilySync(String fontFamily) => fontFamily;

  @override
  Future<String?> ensureLoaded(String fontPath) async => fontPath;

  @override
  Future<String> resolveFamily(String fontFamily) async => fontFamily;

  @override
  Future<Directory> fontDirectory() async => Directory.systemTemp;

  @override
  Future<List<File>> listCustomFontFiles() async => <File>[];

  @override
  TextStyle contentTextStyle({
    required ReaderSettings settings,
    required Color color,
    String? resolvedFamily,
    double? renderedLineHeight,
  }) => TextStyle(
    color: color,
    fontSize: settings.fontSize,
    fontFamily: resolvedFamily ?? settings.fontFamily,
    height: renderedLineHeight == null
        ? settings.lineHeight
        : renderedLineHeight / settings.fontSize,
  );

  @override
  double? renderedLineHeight({
    required ReaderSettings settings,
    String? resolvedFamily,
  }) => settings.fontSize * settings.lineHeight;
}
