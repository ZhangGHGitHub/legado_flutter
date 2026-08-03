import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_controller.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/providers/book_provider.dart';

import '../helpers/book_source_service_test_factory.dart';

void main() {
  test('loadBooks ignores a stale result from an older request', () async {
    final controller = _DeferredBookshelfController();
    final provider = BookProvider(
      repository: _EmptyBookDao(),
      contentCache: const FileChapterContentCache(),
      sourceService: TestBookSourceService(),
      bookshelfController: controller,
    );

    final first = provider.loadBooks(runMaintenance: false);
    final second = provider.loadBooks(runMaintenance: false);

    final newerBook = const Book(id: 'newer', name: '新请求');
    controller.complete(1, [newerBook]);
    await second;

    final staleBook = const Book(id: 'stale', name: '旧请求');
    controller.complete(0, [staleBook]);
    await first;

    expect(provider.books, [newerBook]);
    expect(provider.isLoading, isFalse);
    expect(provider.loadError, isNull);
  });

  test('a stale failure cannot replace the newer successful result', () async {
    final controller = _DeferredBookshelfController();
    final provider = BookProvider(
      repository: _EmptyBookDao(),
      contentCache: const FileChapterContentCache(),
      sourceService: TestBookSourceService(),
      bookshelfController: controller,
    );

    final first = provider.loadBooks(runMaintenance: false);
    final second = provider.loadBooks(runMaintenance: false);

    final newerBook = const Book(id: 'newer', name: '新请求');
    controller.complete(1, [newerBook]);
    await second;

    controller.fail(0, StateError('旧请求失败'));
    await first;

    expect(provider.books, [newerBook]);
    expect(provider.isLoading, isFalse);
    expect(provider.loadError, isNull);
  });
}

class _DeferredBookshelfController extends BookshelfController {
  _DeferredBookshelfController() : super(_NoopBookshelfPort());

  final _pending = <Completer<List<Book>>>[];

  @override
  Future<List<Book>> loadBookshelf() {
    final completer = Completer<List<Book>>();
    _pending.add(completer);
    return completer.future;
  }

  void complete(int index, List<Book> books) => _pending[index].complete(books);

  void fail(int index, Object error) =>
      _pending[index].completeError(error, StackTrace.current);
}

class _NoopBookshelfPort implements BookshelfPort {
  @override
  Future<List<Book>> loadBookshelf() async => const [];
}

class _EmptyBookDao extends BookDao {
  @override
  Future<List<Book>> getAll() async => const [];

  @override
  Future<List<Chapter>> getChapters(String bookId) async => const [];
}
