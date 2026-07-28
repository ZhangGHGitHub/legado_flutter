/// 原版 `Context.share` 使用的分享选择器标题/主题。
const readerSelectionShareSubject = '分享';

/// 返回原版选区分享应交给系统的文本。
///
/// 选区正文不做 trim 或净化，保持原版 `context.share(selectedText)` 的
/// 原样传递；空选区不产生分享动作。
String? readerSelectionShareText(String selectedText) {
  if (selectedText.isEmpty) return null;
  return selectedText;
}
