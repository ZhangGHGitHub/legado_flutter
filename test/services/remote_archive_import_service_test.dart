import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/remote_archive_import_service.dart';
import 'package:path/path.dart' as p;

void main() {
  test('extracts TXT/EPUB entries and ignores unsupported files', () async {
    final archive = Archive()
      ..addFile(ArchiveFile('books/one.txt', 9, '章节\n正文'.codeUnits))
      ..addFile(ArchiveFile('books/two.epub', 3, [1, 2, 3]))
      ..addFile(ArchiveFile('cover.jpg', 3, [4, 5, 6]));
    final bytes = ZipEncoder().encode(archive);
    final output = await Directory.systemTemp.createTemp('legado-remote-zip-');

    try {
      final files = await const RemoteArchiveImportService()
          .extractZipBookFiles(
            bytes,
            outputDir: output,
            archiveName: 'books.zip',
          );

      expect(
        files.map((path) => p.basename(path)),
        containsAll(<String>['one.txt', 'two.epub']),
      );
      expect(File(files.first).existsSync(), isTrue);
      expect(
        File(p.join(output.path, 'books', 'cover.jpg')).existsSync(),
        isFalse,
      );
    } finally {
      await output.delete(recursive: true);
    }
  });

  test('rejects archive path traversal before writing files', () async {
    final archive = Archive()..addFile(ArchiveFile('../escape.txt', 1, [1]));
    final bytes = ZipEncoder().encode(archive);
    final output = await Directory.systemTemp.createTemp('legado-remote-zip-');

    try {
      await expectLater(
        const RemoteArchiveImportService().extractZipBookFiles(
          bytes,
          outputDir: output,
          archiveName: 'books.zip',
        ),
        throwsA(isA<RemoteArchiveImportException>()),
      );
    } finally {
      await output.delete(recursive: true);
    }
  });

  test('reports a corrupt ZIP as an import error', () async {
    final output = await Directory.systemTemp.createTemp('legado-remote-zip-');

    try {
      await expectLater(
        const RemoteArchiveImportService().extractZipBookFiles(
          <int>[1, 2, 3],
          outputDir: output,
          archiveName: 'broken.zip',
        ),
        throwsA(isA<RemoteArchiveImportException>()),
      );
    } finally {
      await output.delete(recursive: true);
    }
  });
}
