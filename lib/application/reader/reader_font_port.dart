/// 日志等轻量展示场景所需的系统字体能力。
abstract interface class ReaderFontPort {
  String platformSansFamily();

  List<String> cjkFallbackFamilies();
}
