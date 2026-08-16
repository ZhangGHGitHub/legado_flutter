/// 应用层使用的纯文本剪贴板端口。
abstract interface class ClipboardPort {
  Future<void> copyText(String text);

  Future<String?> pasteText();
}
