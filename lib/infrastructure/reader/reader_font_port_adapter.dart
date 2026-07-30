import 'dart:io';

import '../../application/reader/reader_font_port.dart';
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
}
