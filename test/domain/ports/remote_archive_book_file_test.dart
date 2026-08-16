import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/remote_archive_parser_port.dart';

void main() {
  group('RemoteArchiveBookFile', () {
    test('preserves the remote relative path and byte list type', () {
      final file = RemoteArchiveBookFile(
        relativePath: 'books/one.txt',
        bytes: <int>[0, 127, 255],
      );

      expect(file.relativePath, 'books/one.txt');
      expect(file.bytes, <int>[0, 127, 255]);
      expect(file.bytes, isA<List<int>>());
    });

    test('provides Freezed value equality and copyWith semantics', () {
      const original = RemoteArchiveBookFile(
        relativePath: 'books/one.txt',
        bytes: <int>[1, 2, 3],
      );
      const equivalent = RemoteArchiveBookFile(
        relativePath: 'books/one.txt',
        bytes: <int>[1, 2, 3],
      );

      expect(original, equivalent);
      expect(original.hashCode, equivalent.hashCode);
      expect(
        original.copyWith(relativePath: 'books/two.txt'),
        const RemoteArchiveBookFile(
          relativePath: 'books/two.txt',
          bytes: <int>[1, 2, 3],
        ),
      );
    });

    test('retains the original mutable byte list semantics', () {
      final bytes = <int>[4, 5];
      final file = RemoteArchiveBookFile(
        relativePath: 'books/one.epub',
        bytes: bytes,
      );

      bytes[0] = 9;
      file.bytes[1] = 6;

      expect(file.bytes, <int>[9, 6]);
      expect(bytes, <int>[9, 6]);
    });
  });

  group('RemoteArchiveParserException', () {
    test('keeps the original exception text', () {
      const message = 'ZIP 解析失败: 不支持的压缩包';
      const exception = RemoteArchiveParserException(message);

      expect(exception.message, message);
      expect(exception.toString(), message);
    });
  });
}
