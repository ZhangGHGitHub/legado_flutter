import 'package:flutter/services.dart';

/// Clipboard boundary used by the donation page.
abstract interface class DonateClipboardPort {
  Future<void> copyText(String text);
}

/// Production adapter for the platform clipboard.
class PlatformDonateClipboard implements DonateClipboardPort {
  const PlatformDonateClipboard();

  @override
  Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
