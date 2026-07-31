import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/local_book_import_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/infrastructure/book/local_book_import_port_adapter.dart';
import 'package:legado_flutter/services/local_book_service.dart';

void main() {
  test('importFromFile delegates and preserves cancellation', () async {
    final service = _FakeLocalBookService(fileResult: null);
    final port = LocalBookImportPortAdapter(service);

    expect(await port.importFromFile(), isNull);
    expect(service.fileCalls, 1);
  });

  test('importFromFile returns the exact imported book', () async {
    final book = Book(id: 'local-1', name: '本地书', author: '本地导入');
    final service = _FakeLocalBookService(fileResult: book);
    final port = LocalBookImportPortAdapter(service);

    expect(await port.importFromFile(), same(book));
    expect(service.fileCalls, 1);
  });

  test('importFromPath forwards path and displayName unchanged', () async {
    final book = Book(id: 'local-2', name: '显示书名', author: '本地导入');
    final service = _FakeLocalBookService(pathResult: book);
    final port = LocalBookImportPortAdapter(service);

    expect(
      await port.importFromPath(
        'D:\\books\\download.tmp',
        displayName: '书名.epub',
      ),
      same(book),
    );
    expect(service.pathCalls, 1);
    expect(service.receivedPath, 'D:\\books\\download.tmp');
    expect(service.receivedDisplayName, '书名.epub');
  });

  test('importFromPath preserves an omitted displayName', () async {
    final book = Book(id: 'local-3', name: 'book', author: '本地导入');
    final service = _FakeLocalBookService(pathResult: book);
    final port = LocalBookImportPortAdapter(service);

    await port.importFromPath('D:\\books\\book.txt');

    expect(service.receivedPath, 'D:\\books\\book.txt');
    expect(service.receivedDisplayName, isNull);
  });

  test('maps file import error without changing its message', () async {
    final service = _FakeLocalBookService(
      fileError: LocalBookImportException('文件过大（60.0MB）'),
    );
    final port = LocalBookImportPortAdapter(service);

    await expectLater(
      port.importFromFile(),
      throwsA(
        isA<LocalBookImportPortException>().having(
          (error) => error.message,
          'message',
          '文件过大（60.0MB）',
        ),
      ),
    );
  });

  test('maps path import error without changing its message', () async {
    final service = _FakeLocalBookService(
      pathError: LocalBookImportException('仅支持 txt / epub 文件'),
    );
    final port = LocalBookImportPortAdapter(service);

    await expectLater(
      port.importFromPath('D:\\books\\book.pdf', displayName: 'book.pdf'),
      throwsA(
        isA<LocalBookImportPortException>().having(
          (error) => error.message,
          'message',
          '仅支持 txt / epub 文件',
        ),
      ),
    );
  });

  test('does not hide unrelated service failures', () async {
    final service = _FakeLocalBookService(pathError: StateError('repository'));
    final port = LocalBookImportPortAdapter(service);

    await expectLater(
      port.importFromPath('D:\\books\\book.txt'),
      throwsA(isA<StateError>()),
    );
  });
}

final class _FakeLocalBookService implements LocalBookService {
  _FakeLocalBookService({
    this.fileResult,
    this.pathResult,
    this.fileError,
    this.pathError,
  });

  final Book? fileResult;
  final Book? pathResult;
  final Object? fileError;
  final Object? pathError;

  int fileCalls = 0;
  int pathCalls = 0;
  String? receivedPath;
  String? receivedDisplayName;

  @override
  Future<Book?> importFromFile() async {
    fileCalls += 1;
    if (fileError case final error?) throw error;
    return fileResult;
  }

  @override
  Future<Book> importFromPath(String filePath, {String? displayName}) async {
    pathCalls += 1;
    receivedPath = filePath;
    receivedDisplayName = displayName;
    if (pathError case final error?) throw error;
    return pathResult!;
  }
}
