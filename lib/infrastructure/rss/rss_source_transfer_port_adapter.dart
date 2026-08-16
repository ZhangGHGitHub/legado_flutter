import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../../application/rss/rss_source_transfer_port.dart';

/// Adapts the platform file picker and clipboard to the RSS source port.
final class RssSourceTransferPortAdapter implements RssSourceTransferPort {
  const RssSourceTransferPortAdapter();

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
