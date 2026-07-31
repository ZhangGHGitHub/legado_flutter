import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/remote_archive_import_port.dart';

void main() {
  test('exposes the archive import contract without service details', () async {
    final port = _MemoryRemoteArchiveImportPort();
    final output = await Directory.systemTemp.createTemp('legado-remote-port-');

    try {
      final paths = await port.extractZipBookFiles(
        const [1, 2, 3],
        outputDir: output,
        archiveName: 'books.zip',
      );

      expect(paths, [output.path]);
      expect(port.input, [1, 2, 3]);
      expect(port.archiveName, 'books.zip');
    } finally {
      await output.delete(recursive: true);
    }
  });
}

final class _MemoryRemoteArchiveImportPort implements RemoteArchiveImportPort {
  List<int>? input;
  String? archiveName;

  @override
  Future<List<String>> extractZipBookFiles(
    List<int> bytes, {
    required Directory outputDir,
    required String archiveName,
  }) async {
    input = List<int>.from(bytes);
    this.archiveName = archiveName;
    return [outputDir.path];
  }
}
