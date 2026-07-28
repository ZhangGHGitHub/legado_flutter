import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

/// File and clipboard operations used by the RSS source management page.
abstract class RssSourceTransferPort {
  Future<String?> pickImportText();

  Future<void> copyText(String text);
}

/// Platform implementation kept outside the page so the UI can be tested
/// without invoking a native file picker or clipboard.
class PlatformRssSourceTransfer implements RssSourceTransferPort {
  const PlatformRssSourceTransfer();

  @override
  Future<String?> pickImportText() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json', 'txt'],
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    if (path == null) return null;
    return File(path).readAsString();
  }

  @override
  Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
