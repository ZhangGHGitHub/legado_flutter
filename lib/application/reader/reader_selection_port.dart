/// 阅读器选区浏览与分享文本规范的应用层边界。
abstract interface class ReaderSelectionPort {
  bool isAbsoluteWebUrl(String selectedText);

  Uri? browserUri(String selectedText);

  Future<bool> tryNativeWebSearch(String selectedText);

  String? shareText(String selectedText);

  String get shareSubject;
}
