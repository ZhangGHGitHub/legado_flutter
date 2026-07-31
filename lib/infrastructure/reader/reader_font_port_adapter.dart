import 'dart:io';

import 'package:flutter/material.dart';

import '../../application/reader/reader_font_port.dart';
import '../../features/reader/reader_settings.dart';
import '../../services/reader_font_loader.dart';

final class ReaderFontPortAdapter implements ReaderFontPort {
  const ReaderFontPortAdapter();

  @override
  String platformSansFamily() => ReaderFontLoader.platformSansFamily();

  @override
  String platformSerifFamily() => ReaderFontLoader.platformSerifFamily();

  @override
  String platformMonoFamily() => ReaderFontLoader.platformMonoFamily();

  @override
  List<String> cjkFallbackFamilies() => ReaderFontLoader.cjkFallbackFamilies();

  @override
  bool isFontFilePath(String value) => ReaderFontLoader.isFontFilePath(value);

  @override
  String displayName(String fontFamily) =>
      ReaderFontLoader.displayName(fontFamily);

  @override
  String resolveFamilySync(String fontFamily) =>
      ReaderFontLoader.resolveFamilySync(fontFamily);

  @override
  Future<String?> ensureLoaded(String fontPath) =>
      ReaderFontLoader.ensureLoaded(fontPath);

  @override
  Future<String> resolveFamily(String fontFamily) =>
      ReaderFontLoader.resolveFamily(fontFamily);

  @override
  Future<Directory> fontDirectory() => ReaderFontLoader.fontDirectory();

  @override
  Future<List<File>> listCustomFontFiles() =>
      ReaderFontLoader.listCustomFontFiles();

  @override
  TextStyle contentTextStyle({
    required ReaderSettings settings,
    required Color color,
    String? resolvedFamily,
    double? renderedLineHeight,
  }) => ReaderFontLoader.contentTextStyle(
    settings: settings,
    color: color,
    resolvedFamily: resolvedFamily,
    renderedLineHeight: renderedLineHeight,
  );

  @override
  double? renderedLineHeight({
    required ReaderSettings settings,
    String? resolvedFamily,
  }) => ReaderFontLoader.renderedLineHeight(
    settings: settings,
    resolvedFamily: resolvedFamily,
  );
}
