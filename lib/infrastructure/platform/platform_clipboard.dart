import 'package:flutter/services.dart';

import '../../application/platform/clipboard_port.dart';

/// 使用 Flutter 平台剪贴板实现应用层端口。
final class PlatformClipboard implements ClipboardPort {
  const PlatformClipboard();

  @override
  Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Future<String?> pasteText() async {
    final data = await Clipboard.getData('text/plain');
    return data?.text;
  }
}
