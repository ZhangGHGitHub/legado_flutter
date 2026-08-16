import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/remote_archive_parser_port.dart';
import 'package:legado_flutter/infrastructure/engine/frb_remote_archive_parser_port.dart';
import 'package:legado_flutter/src/rust/api.dart' as rust_api;
import 'package:legado_flutter/src/rust/api/error.dart';

void main() {
  test('maps Rust archive files without changing order, paths, or bytes', () {
    final port = FrbRemoteArchiveParserPort(
      isAvailable: () => true,
      parseRemoteArchiveBookFiles: ({required data}) {
        expect(data, <int>[1, 2, 3]);
        return [
          rust_api.RemoteArchiveBookFile(
            relativePath: 'books/one.txt',
            bytes: Uint8List.fromList(<int>[4, 5]),
          ),
          rust_api.RemoteArchiveBookFile(
            relativePath: 'books/two.epub',
            bytes: Uint8List.fromList(<int>[6, 7]),
          ),
        ];
      },
    );

    final files = port.parseZipBookFiles(<int>[1, 2, 3]);

    expect(files.map((file) => file.relativePath), <String>[
      'books/one.txt',
      'books/two.epub',
    ]);
    expect(files.map((file) => file.bytes), <List<int>>[
      <int>[4, 5],
      <int>[6, 7],
    ]);
  });

  test('fails explicitly when the Rust engine is unavailable', () {
    const port = FrbRemoteArchiveParserPort(isAvailable: _unavailable);

    expect(() => port.parseZipBookFiles(const <int>[]), throwsStateError);
  });

  test('keeps the original Rust parse error text at the domain port', () {
    const message = 'ZIP 解析失败: 不支持的压缩包';
    final port = FrbRemoteArchiveParserPort(
      isAvailable: () => true,
      parseRemoteArchiveBookFiles: ({required data}) {
        throw AppError.parse(message);
      },
    );

    expect(
      () => port.parseZipBookFiles(const <int>[]),
      throwsA(
        isA<RemoteArchiveParserException>().having(
          (error) => error.message,
          'message',
          message,
        ),
      ),
    );
  });
}

bool _unavailable() => false;
