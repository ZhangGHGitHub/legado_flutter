import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/remote_archive_parser_port.dart';
import 'package:legado_flutter/services/remote_archive_import_service.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'writes Rust-approved TXT/EPUB entries without changing order',
    () async {
      final parser = _FakeRemoteArchiveParser(
        files: [
          RemoteArchiveBookFile(
            relativePath: 'books/one.txt',
            bytes: '章节\n正文'.codeUnits,
          ),
          const RemoteArchiveBookFile(
            relativePath: 'books/two.epub',
            bytes: <int>[1, 2, 3],
          ),
        ],
      );
      final output = await Directory.systemTemp.createTemp(
        'legado-remote-zip-',
      );

      try {
        final files = await RemoteArchiveImportService(parser: parser)
            .extractZipBookFiles(
              <int>[9, 8, 7],
              outputDir: output,
              archiveName: 'books.zip',
            );

        expect(files.map((path) => p.basename(path)), <String>[
          'one.txt',
          'two.epub',
        ]);
        expect(parser.input, <int>[9, 8, 7]);
        expect(File(files.first).existsSync(), isTrue);
        expect(
          File(p.join(output.path, 'books', 'cover.jpg')).existsSync(),
          isFalse,
        );
      } finally {
        await output.delete(recursive: true);
      }
    },
  );

  test(
    'propagates Rust path traversal rejection before writing files',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'legado-remote-zip-',
      );

      try {
        await expectLater(
          RemoteArchiveImportService(
            parser: _FakeRemoteArchiveParser(
              error: '压缩包包含不安全路径: ../escape.txt',
            ),
          ).extractZipBookFiles(
            const <int>[1],
            outputDir: output,
            archiveName: 'books.zip',
          ),
          throwsA(
            isA<RemoteArchiveImportException>().having(
              (error) => error.message,
              'message',
              contains('不安全路径'),
            ),
          ),
        );
        expect(output.listSync(recursive: true), isEmpty);
      } finally {
        await output.delete(recursive: true);
      }
    },
  );

  test('reports a corrupt ZIP as an import error', () async {
    final output = await Directory.systemTemp.createTemp('legado-remote-zip-');

    try {
      await expectLater(
        RemoteArchiveImportService(
          parser: _FakeRemoteArchiveParser(error: 'ZIP 压缩包损坏或无法读取'),
        ).extractZipBookFiles(
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

class _FakeRemoteArchiveParser implements RemoteArchiveParserPort {
  _FakeRemoteArchiveParser({this.files = const [], this.error});

  final List<RemoteArchiveBookFile> files;
  final String? error;
  List<int>? input;

  @override
  bool get isAvailable => true;

  @override
  List<RemoteArchiveBookFile> parseZipBookFiles(List<int> bytes) {
    input = List<int>.from(bytes);
    if (error case final message?) throw Exception(message);
    return files;
  }
}
