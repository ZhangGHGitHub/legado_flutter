import 'dart:io' show Platform;

import 'package:flutter/services.dart';

bool readerSelectionIsAbsoluteWebUrl(String selectedText) {
  // Matches legado's String.isAbsUrl(): classification is prefix-based.
  // URI parsing remains a separate step for the ACTION_VIEW target.
  final lower = selectedText.toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

/// Android 上优先还原原版 `Intent.ACTION_WEB_SEARCH`。
Future<bool> tryNativeReaderWebSearch(String selectedText) async {
  if (!Platform.isAndroid) return false;
  final query = selectedText.trim();
  if (query.isEmpty) return false;
  try {
    return await const MethodChannel(
          'legado_flutter/system',
        ).invokeMethod<bool>('webSearch', <String, String>{'query': query}) ??
        false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}

/// 将原版选区浏览器动作映射为可由 Flutter 外部浏览器打开的 URI。
///
/// 原版对绝对网页地址使用 ACTION_VIEW，对普通文本使用
/// ACTION_WEB_SEARCH。Flutter 没有跨平台的 ACTION_WEB_SEARCH API，使用
/// Google Web Search URL 保留“按文本搜索”语义；实际打开仍交给系统外部浏览器。
Uri? readerSelectionBrowserUri(String selectedText) {
  final text = selectedText.trim();
  if (text.isEmpty) return null;
  final parsed = Uri.tryParse(text);
  if (readerSelectionIsAbsoluteWebUrl(text)) {
    return parsed;
  }
  return Uri.https('www.google.com', '/search', <String, String>{'q': text});
}
