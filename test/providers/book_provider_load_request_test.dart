import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_change_port.dart';
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

  test(
    'a stale load cannot replace a newer successful bookshelf write',
    () async {
      final controller = _DeferredBookshelfController();
      final changes = BookshelfChangeBus();
      final latestBook = const Book(id: 'latest', name: '写入后的书');
      final provider = BookProvider(
        repository: _MutationBookDao(latestBook),
        contentCache: const FileChapterContentCache(),
        sourceService: TestBookSourceService(),
        bookshelfController: controller,
        bookshelfChangePort: changes,
      );
      addTearDown(changes.dispose);

      final load = provider.loadBooks(runMaintenance: false);
      await provider.updateBookGroup('book-1', '新分组');

      controller.complete(0, [const Book(id: 'stale', name: '旧读取')]);
      await load;

      expect(provider.books, [latestBook]);
      expect(changes.latest?.books, [latestBook]);
      expect(provider.isLoading, isFalse);
    },
  );

  test('a stale load cannot replace a newer cover write', () async {
    final controller = _DeferredBookshelfController();
    final changes = BookshelfChangeBus();
    final original = const Book(
      id: 'book-1',
      name: '测试书',
      coverUrl: 'https://cover/old',
      currentPageIndex: 65537,
    );
    final provider = BookProvider(
      repository: _CoverBookDao(),
      contentCache: const FileChapterContentCache(),
      sourceService: TestBookSourceService(),
      bookshelfController: controller,
      bookshelfChangePort: changes,
    );
    addTearDown(changes.dispose);

    final initialLoad = provider.loadBooks(runMaintenance: false);
    controller.complete(0, [original]);
    await initialLoad;

    final staleLoad = provider.loadBooks(runMaintenance: false);
    final updated = await provider.updateBookCover(
      original,
      'https://cover/new',
    );
    controller.complete(1, [original]);
    await staleLoad;

    expect(updated.coverUrl, 'https://cover/new');
    expect(updated.currentPageIndex, 65537);
    expect(provider.books, [updated]);
    expect(changes.latest?.books, [updated]);
    expect(provider.isLoading, isFalse);
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

class _MutationBookDao extends BookDao {
  _MutationBookDao(this.latestBook);

  final Book latestBook;

  @override
  Future<void> updateGroup(String bookId, String group) async {}

  @override
  Future<List<Book>> getAll() async => [latestBook];

  @override
  Future<List<Chapter>> getChapters(String bookId) async => const [];
}

class _CoverBookDao extends BookDao {
  @override
  Future<void> updateCover(String bookId, String coverUrl) async {}
}
