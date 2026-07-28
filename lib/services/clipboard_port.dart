import 'package:flutter/services.dart';

/// Shared text clipboard boundary for pages that copy or paste plain text.
abstract interface class ClipboardPort {
  Future<void> copyText(String text);

  Future<String?> pasteText();
}

/// Production adapter for the platform clipboard.
class PlatformClipboard implements ClipboardPort {
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
