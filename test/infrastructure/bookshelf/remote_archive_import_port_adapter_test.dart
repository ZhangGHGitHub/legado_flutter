import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/remote_archive_parser_port.dart';
import 'package:legado_flutter/infrastructure/bookshelf/remote_archive_import_port_adapter.dart';
import 'package:legado_flutter/services/remote_archive_import_service.dart';
import 'package:path/path.dart' as p;

void main() {
  test('adapts the existing ZIP importer and preserves file output', () async {
    final output = await Directory.systemTemp.createTemp(
      'legado-remote-adapter-',
    );

    try {
      final adapter = RemoteArchiveImportPortAdapter(
        RemoteArchiveImportService(
          parser: _FakeParser(
            files: [
              const RemoteArchiveBookFile(
                relativePath: 'book.txt',
                bytes: [1, 2, 3],
              ),
            ],
          ),
        ),
      );
      final files = await adapter.extractZipBookFiles(
        const [9],
        outputDir: output,
        archiveName: 'remote.zip',
      );

      expect(files.map(p.basename), ['book.txt']);
      expect(File(files.single).readAsBytesSync(), [1, 2, 3]);
    } finally {
      await output.delete(recursive: true);
    }
  });
}

final class _FakeParser implements RemoteArchiveParserPort {
  const _FakeParser({required this.files});

  final List<RemoteArchiveBookFile> files;

  @override
  bool get isAvailable => true;

  @override
  List<RemoteArchiveBookFile> parseZipBookFiles(List<int> bytes) => files;
}
