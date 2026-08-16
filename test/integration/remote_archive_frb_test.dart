import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/infrastructure/engine/frb_remote_archive_parser_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await LegadoEngineBridge.tryInit();
    expect(
      LegadoEngineBridge.isAvailable,
      isTrue,
      reason: '请先构建当前 Rust 动态库，不能用 Dart ZIP 解析代替 FRB 门禁',
    );
  });

  test(
    'real Rust ZIP parser returns only importable files in archive order',
    () {
      final archive = Archive()
        ..addFile(ArchiveFile('books/one.txt', 3, <int>[1, 2, 3]))
        ..addFile(ArchiveFile('cover.jpg', 2, <int>[4, 5]))
        ..addFile(ArchiveFile('books/two.epub', 2, <int>[6, 7]));

      final files = const FrbRemoteArchiveParserPort().parseZipBookFiles(
        ZipEncoder().encode(archive),
      );

      expect(files.map((file) => file.relativePath), <String>[
        'books/one.txt',
        'books/two.epub',
      ]);
      expect(files.map((file) => file.bytes), <List<int>>[
        <int>[1, 2, 3],
        <int>[6, 7],
      ]);
    },
  );

  test('real Rust ZIP parser rejects traversal paths', () {
    final archive = Archive()
      ..addFile(ArchiveFile('../escape.txt', 1, <int>[1]));

    expect(
      () => const FrbRemoteArchiveParserPort().parseZipBookFiles(
        ZipEncoder().encode(archive),
      ),
      throwsA(
        predicate<Object>(
          (error) => error.toString().contains('不安全路径'),
          '包含路径安全错误',
        ),
      ),
    );
  });
}
