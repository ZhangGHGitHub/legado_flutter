import 'package:flutter/services.dart';

import '../../application/donate/donate_clipboard_port.dart';

/// 使用 Flutter 平台剪贴板实现捐赠页的复制能力。
final class PlatformDonateClipboard implements DonateClipboardPort {
  const PlatformDonateClipboard();

  @override
  Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
