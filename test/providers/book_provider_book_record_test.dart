import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_change_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/providers/book_provider.dart';

import '../helpers/book_source_service_test_factory.dart';

final class _RecordBookRepository implements BookRepository {
  _RecordBookRepository([Book? book]) : books = [?book];

  final List<Book> books;
  bool failCoverWrite = false;
  bool failDetailsWrite = false;
  Completer<List<Book>>? delayedGetAll;
  final List<String> calls = [];

  @override
  Future<List<Book>> getAll() async {
    calls.add('getAll');
    final delayed = delayedGetAll;
    if (delayed != null) return delayed.future;
    return List<Book>.of(books);
  }

  @override
  Future<void> updateCover(String bookId, String coverUrl) async {
    calls.add('updateCover:$bookId:$coverUrl');
    if (failCoverWrite) throw StateError('封面写入失败');
    final index = books.indexWhere((book) => book.id == bookId);
    books[index] = books[index].copyWith(coverUrl: coverUrl);
  }

  @override
  Future<void> updateBookDetails(
    String bookId,
    String name,
    String author,
    String description,
  ) async {
    calls.add('updateBookDetails:$bookId:$name:$author:$description');
    if (failDetailsWrite) throw StateError('基础信息写入失败');
    final index = books.indexWhere((book) => book.id == bookId);
    books[index] = books[index].copyWith(
      name: name,
      author: author,
      description: description,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Book _latestBook() => Book(
  id: 'book-1',
  name: '旧书名',
  author: '旧作者',
  coverUrl: 'https://cover/current',
  progress: 0.75,
  currentChapter: '第九章',
  durChapterIndex: 8,
  currentPageIndex: 65537,
  readConfig: const BookReadConfig(
    reverseToc: true,
    extra: {'legacyField': 'kept'},
  ),
  sourceUrl: 'https://source/book-1',
  bookSourceUrl: 'https://source',
  tocUrl: 'https://source/book-1/toc',
  readIteration: 3,
);

BookProvider _provider(
  _RecordBookRepository repository,
  BookshelfChangePort changes,
) => BookProvider(
  repository: repository,
  sourceService: TestBookSourceService(),
  contentCache: const FileChapterContentCache(),
  bookshelfChangePort: changes,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('封面更新使用最新书架记录并发布刷新后的快照', () async {
    final repository = _RecordBookRepository(_latestBook());
    final changes = BookshelfChangeBus();
    final provider = _provider(repository, changes);
    addTearDown(changes.dispose);
    await provider.loadBooks(runMaintenance: false);
    repository.calls.clear();

    final updated = await provider.updateBookCover(
      const Book(id: 'book-1', name: '过期页面记录'),
      'https://cover/new',
    );

    expect(repository.calls, ['updateCover:book-1:https://cover/new']);
    expect(updated.coverUrl, 'https://cover/new');
    expect(updated.currentPageIndex, 65537);
    expect(updated.durChapterIndex, 8);
    expect(provider.books.single, same(updated));
    expect(changes.latest?.books.single, same(updated));
  });

  test('封面写入失败时不刷新列表也不发布新快照', () async {
    final repository = _RecordBookRepository(_latestBook());
    final changes = BookshelfChangeBus();
    final provider = _provider(repository, changes);
    addTearDown(changes.dispose);
    await provider.loadBooks(runMaintenance: false);
    final revision = changes.revision;
    repository
      ..calls.clear()
      ..failCoverWrite = true;

    await expectLater(
      provider.updateBookCover(_latestBook(), 'https://cover/failed'),
      throwsA(isA<StateError>()),
    );

    expect(repository.calls, ['updateCover:book-1:https://cover/failed']);
    expect(provider.books.single.coverUrl, 'https://cover/current');
    expect(changes.revision, revision);
  });

  test('基础信息更新仅覆盖三字段并保留最新阅读和来源状态', () async {
    final latest = _latestBook();
    final repository = _RecordBookRepository(latest);
    final changes = BookshelfChangeBus();
    final provider = _provider(repository, changes);
    addTearDown(changes.dispose);
    await provider.loadBooks(runMaintenance: false);
    repository.calls.clear();

    final updated = await provider.updateBookDetails(
      latest.id,
      name: ' 新书名 ',
      author: ' 新作者 ',
      description: ' 新简介 ',
    );

    expect(repository.calls, ['updateBookDetails:book-1:新书名:新作者:新简介']);
    expect(updated, isNotNull);
    expect(
      updated,
      latest.copyWith(name: '新书名', author: '新作者', description: '新简介'),
    );
    expect(updated!.currentPageIndex, 65537);
    expect(updated.durChapterIndex, 8);
    expect(updated.progress, 0.75);
    expect(updated.coverUrl, 'https://cover/current');
    expect(updated.sourceUrl, 'https://source/book-1');
    expect(updated.bookSourceUrl, 'https://source');
    expect(updated.tocUrl, 'https://source/book-1/toc');
    expect(updated.readConfig.extra, {'legacyField': 'kept'});
    expect(provider.books.single, same(updated));
    expect(changes.latest?.books.single, same(updated));
  });

  test('基础信息写入失败时不修改书架也不发布快照', () async {
    final latest = _latestBook();
    final repository = _RecordBookRepository(latest);
    final changes = BookshelfChangeBus();
    final provider = _provider(repository, changes);
    addTearDown(changes.dispose);
    await provider.loadBooks(runMaintenance: false);
    final revision = changes.revision;
    repository
      ..calls.clear()
      ..failDetailsWrite = true;

    await expectLater(
      provider.updateBookDetails(
        latest.id,
        name: '新书名',
        author: '新作者',
        description: '新简介',
      ),
      throwsA(isA<StateError>()),
    );

    expect(provider.books.single, latest);
    expect(changes.revision, revision);
  });

  test('非书架书籍不执行基础信息写入', () async {
    final repository = _RecordBookRepository();
    final changes = BookshelfChangeBus();
    final provider = _provider(repository, changes);
    addTearDown(changes.dispose);

    final updated = await provider.updateBookDetails(
      'missing-book',
      name: '新书名',
      author: '新作者',
      description: '新简介',
    );

    expect(updated, isNull);
    expect(repository.calls, isEmpty);
    expect(changes.revision, 0);
  });

  test('基础信息更新使较早启动的旧书架加载失效', () async {
    final latest = _latestBook();
    final repository = _RecordBookRepository(latest);
    final changes = BookshelfChangeBus();
    final provider = _provider(repository, changes);
    addTearDown(changes.dispose);
    await provider.loadBooks(runMaintenance: false);

    final staleLoad = Completer<List<Book>>();
    repository.delayedGetAll = staleLoad;
    final loadFuture = provider.loadBooks(runMaintenance: false);
    await Future<void>.delayed(Duration.zero);

    await provider.updateBookDetails(
      latest.id,
      name: '新书名',
      author: '新作者',
      description: '新简介',
    );
    staleLoad.complete([latest]);
    await loadFuture;

    expect(provider.books.single.name, '新书名');
    expect(provider.books.single.currentPageIndex, 65537);
    expect(changes.latest?.books.single.name, '新书名');
  });
}
