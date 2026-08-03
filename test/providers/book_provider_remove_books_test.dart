import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_change_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';
import 'package:legado_flutter/model/read_book.dart';
import 'package:legado_flutter/providers/book_provider.dart';

import '../helpers/book_source_service_test_factory.dart';

Book _book(String id) => Book(id: id, name: '书籍$id');

final class _FakeBookRepository implements BookRepository {
  _FakeBookRepository(Iterable<Book> books, this.operations)
    : storedBooks = List<Book>.of(books);

  final List<String> operations;
  final List<Book> storedBooks;
  final Map<String, Object> deleteErrors = <String, Object>{};
  Object? getAllError;
  int getAllCalls = 0;

  @override
  Future<void> delete(String bookId) async {
    operations.add('delete:$bookId');
    if (deleteErrors[bookId] case final error?) throw error;
    storedBooks.removeWhere((book) => book.id == bookId);
  }

  @override
  Future<List<Book>> getAll() async {
    operations.add('getAll');
    getAllCalls++;
    if (getAllError case final error?) throw error;
    return List<Book>.of(storedBooks);
  }

  @override
  Future<void> insert(Book book) async {}

  @override
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
  }) async {}

  @override
  Future<void> updateCover(String bookId, String coverUrl) async {}

  @override
  Future<void> updateBookDetails(
    String bookId,
    String name,
    String author,
    String description,
  ) async {}

  @override
  Future<void> updateGroup(String bookId, String group) async {}

  @override
  Future<void> insertChapters(List<Chapter> chapters) async {}

  @override
  Future<List<Chapter>> getChapters(String bookId) async => const [];

  @override
  Future<String?> getChapterContent(String chapterId) async => null;

  @override
  Future<void> saveChapterContent(String chapterId, String content) async {}

  @override
  Future<void> clearChapterContent(Chapter chapter) async {}
}

final class _FakeChapterContentCache implements ChapterContentCachePort {
  _FakeChapterContentCache(this.operations);

  final List<String> operations;
  final List<String> clearedBookIds = <String>[];
  final Map<String, Object> clearErrors = <String, Object>{};

  @override
  Future<void> clearBook(String bookId) async {
    operations.add('clearBook:$bookId');
    clearedBookIds.add(bookId);
    if (clearErrors[bookId] case final error?) throw error;
  }

  @override
  Future<String?> get(String bookId, String chapterId) async => null;

  @override
  Future<void> save(String bookId, String chapterId, String content) async {}

  @override
  Future<void> delete(String bookId, String chapterId) async {}

  @override
  Future<void> clearAll() async {}

  @override
  Future<int> clearInvalid(Set<String> validBookIds) async => 0;

  @override
  Future<bool> has(String bookId, String chapterId) async => false;

  @override
  Future<Set<String>> listChapterIds(String bookId) async => const {};

  @override
  String sanitizeChapterId(String chapterId) => chapterId;

  @override
  Future<Map<String, int>> mapWordCounts(
    String bookId, {
    Set<String>? chapterIds,
  }) async => const {};

  @override
  Future<({int bytes, int chapterFiles})> stats(String bookId) async =>
      (bytes: 0, chapterFiles: 0);
}

final class _Harness {
  _Harness._({
    required this.repository,
    required this.cache,
    required this.changes,
    required this.provider,
    required this.operations,
  });

  final _FakeBookRepository repository;
  final _FakeChapterContentCache cache;
  final BookshelfChangeBus changes;
  final BookProvider provider;
  final List<String> operations;

  static Future<_Harness> create(List<Book> books) async {
    final operations = <String>[];
    final repository = _FakeBookRepository(books, operations);
    final cache = _FakeChapterContentCache(operations);
    final changes = BookshelfChangeBus();
    final provider = BookProvider(
      repository: repository,
      sourceService: TestBookSourceService(),
      contentCache: cache,
      bookshelfChangePort: changes,
    );
    await provider.loadBooks(runMaintenance: false);
    operations.clear();
    repository.getAllCalls = 0;
    return _Harness._(
      repository: repository,
      cache: cache,
      changes: changes,
      provider: provider,
      operations: operations,
    );
  }

  void dispose() {
    provider.dispose();
    changes.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(ReadBook.instance.reset);

  group('BookProvider.removeBooks', () {
    test(
      'success deletes and clears each book in order then publishes once',
      () async {
        final harness = await _Harness.create([
          _book('one'),
          _book('two'),
          _book('three'),
        ]);
        addTearDown(harness.dispose);
        final revision = harness.changes.revision;
        final changes = <BookshelfChange>[];
        final subscription = harness.changes.changes.listen(changes.add);
        addTearDown(subscription.cancel);
        var listenerCalls = 0;
        harness.provider.addListener(() => listenerCalls++);

        await harness.provider.removeBooks(['two', 'one']);

        expect(harness.operations, [
          'delete:two',
          'clearBook:two',
          'delete:one',
          'clearBook:one',
          'getAll',
        ]);
        expect(harness.repository.getAllCalls, 1);
        expect(harness.repository.storedBooks.map((book) => book.id), [
          'three',
        ]);
        expect(harness.cache.clearedBookIds, ['two', 'one']);
        expect(harness.provider.books.map((book) => book.id), ['three']);
        expect(harness.changes.revision, revision + 1);
        expect(changes, hasLength(1));
        expect(changes.single.books.map((book) => book.id), ['three']);
        expect(listenerCalls, 1);
      },
    );

    test(
      'second repository failure preserves first effects and stops the batch',
      () async {
        final harness = await _Harness.create([
          _book('one'),
          _book('two'),
          _book('three'),
        ]);
        addTearDown(harness.dispose);
        final failure = StateError('第二本仓储删除失败');
        harness.repository.deleteErrors['two'] = failure;
        final revision = harness.changes.revision;
        final changes = <BookshelfChange>[];
        final subscription = harness.changes.changes.listen(changes.add);
        addTearDown(subscription.cancel);
        var listenerCalls = 0;
        harness.provider.addListener(() => listenerCalls++);

        await expectLater(
          harness.provider.removeBooks(['one', 'two', 'three']),
          throwsA(same(failure)),
        );

        expect(harness.operations, [
          'delete:one',
          'clearBook:one',
          'delete:two',
        ]);
        expect(harness.repository.storedBooks.map((book) => book.id), [
          'two',
          'three',
        ]);
        expect(harness.cache.clearedBookIds, ['one']);
        expect(harness.repository.getAllCalls, 0);
        expect(harness.provider.books.map((book) => book.id), [
          'one',
          'two',
          'three',
        ]);
        expect(harness.changes.revision, revision);
        expect(changes, isEmpty);
        expect(listenerCalls, 0);
      },
    );

    test(
      'second cache failure keeps its repository deletion but skips refresh',
      () async {
        final harness = await _Harness.create([
          _book('one'),
          _book('two'),
          _book('three'),
        ]);
        addTearDown(harness.dispose);
        final failure = StateError('第二本缓存清理失败');
        harness.cache.clearErrors['two'] = failure;
        final revision = harness.changes.revision;
        final changes = <BookshelfChange>[];
        final subscription = harness.changes.changes.listen(changes.add);
        addTearDown(subscription.cancel);
        var listenerCalls = 0;
        harness.provider.addListener(() => listenerCalls++);

        await expectLater(
          harness.provider.removeBooks(['one', 'two', 'three']),
          throwsA(same(failure)),
        );

        expect(harness.operations, [
          'delete:one',
          'clearBook:one',
          'delete:two',
          'clearBook:two',
        ]);
        expect(harness.repository.storedBooks.map((book) => book.id), [
          'three',
        ]);
        expect(harness.cache.clearedBookIds, ['one', 'two']);
        expect(harness.repository.getAllCalls, 0);
        expect(harness.provider.books.map((book) => book.id), [
          'one',
          'two',
          'three',
        ]);
        expect(harness.changes.revision, revision);
        expect(changes, isEmpty);
        expect(listenerCalls, 0);
      },
    );

    test(
      'final refresh failure leaves the old snapshot and publishes nothing',
      () async {
        final harness = await _Harness.create([
          _book('one'),
          _book('two'),
          _book('three'),
        ]);
        addTearDown(harness.dispose);
        final failure = StateError('最终书架刷新失败');
        harness.repository.getAllError = failure;
        final revision = harness.changes.revision;
        final changes = <BookshelfChange>[];
        final subscription = harness.changes.changes.listen(changes.add);
        addTearDown(subscription.cancel);
        var listenerCalls = 0;
        harness.provider.addListener(() => listenerCalls++);

        await expectLater(
          harness.provider.removeBooks(['one', 'two']),
          throwsA(same(failure)),
        );

        expect(harness.operations, [
          'delete:one',
          'clearBook:one',
          'delete:two',
          'clearBook:two',
          'getAll',
        ]);
        expect(harness.repository.storedBooks.map((book) => book.id), [
          'three',
        ]);
        expect(harness.cache.clearedBookIds, ['one', 'two']);
        expect(harness.repository.getAllCalls, 1);
        expect(harness.provider.books.map((book) => book.id), [
          'one',
          'two',
          'three',
        ]);
        expect(harness.changes.revision, revision);
        expect(changes, isEmpty);
        expect(listenerCalls, 0);
      },
    );
  });
}
