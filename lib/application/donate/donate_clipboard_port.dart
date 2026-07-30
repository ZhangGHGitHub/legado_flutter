/// 捐赠页使用的文本剪贴板边界。
abstract interface class DonateClipboardPort {
  Future<void> copyText(String text);
}
