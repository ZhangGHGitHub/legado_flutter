import 'dart:io';

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
}
