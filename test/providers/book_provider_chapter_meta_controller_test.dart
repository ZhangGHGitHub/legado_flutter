import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_change_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';
import 'package:legado_flutter/providers/book_provider.dart';

import '../helpers/book_source_service_test_factory.dart';

final class _ChapterMetaRepository implements BookRepository {
  _ChapterMetaRepository({required Book book, required List<Chapter> chapters})
    : books = [book],
      chaptersByBook = {book.id: List<Chapter>.from(chapters)};

  final List<Book> books;
  final Map<String, List<Chapter>> chaptersByBook;
  final List<Book> insertedBooks = [];
  Object? insertError;
  int getAllCalls = 0;
  int getChaptersCalls = 0;
  int insertChaptersCalls = 0;
  Completer<void>? getChaptersStarted;
  Completer<void>? releaseGetChapters;
  bool gateFirstGetChapters = true;

  @override
  Future<void> insert(Book book) async {
    if (insertError case final error?) throw error;
    insertedBooks.add(book);
    final index = books.indexWhere((item) => item.id == book.id);
    if (index >= 0) {
      books[index] = book;
    } else {
      books.add(book);
    }
  }

  @override
  Future<List<Book>> getAll() async {
    getAllCalls++;
    return List<Book>.from(books);
  }

  @override
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
  }) async {
    final index = books.indexWhere((item) => item.id == bookId);
    if (index >= 0) {
      books[index] = books[index].copyWith(
        progress: progress,
        currentChapter: chapter,
        currentPageIndex: pageIndex,
      );
    }
  }

  @override
  Future<void> delete(String bookId) async {}

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
  Future<void> insertChapters(List<Chapter> chapters) async {
    insertChaptersCalls++;
    if (chapters.isEmpty) return;
    chaptersByBook[chapters.first.bookId] = List<Chapter>.from(chapters);
  }

  @override
  Future<List<Chapter>> getChapters(String bookId) async {
    getChaptersCalls++;
    final shouldGate = gateFirstGetChapters;
    if (shouldGate) {
      gateFirstGetChapters = false;
      final started = getChaptersStarted;
      if (started != null && !started.isCompleted) started.complete();
    }
    final release = releaseGetChapters;
    if (shouldGate && release != null) {
      await release.future;
    }
    return List<Chapter>.from(chaptersByBook[bookId] ?? const []);
  }

  @override
  Future<String?> getChapterContent(String chapterId) async => null;

  @override
  Future<void> saveChapterContent(String chapterId, String content) async {}

  @override
  Future<void> clearChapterContent(Chapter chapter) async {}
}

final class _ChapterMetaCache implements ChapterContentCachePort {
  int clearInvalidCalls = 0;
  Set<String>? validBookIds;

  @override
  Future<String?> get(String bookId, String chapterId) async => null;

  @override
  Future<void> save(String bookId, String chapterId, String content) async {}

  @override
  Future<void> delete(String bookId, String chapterId) async {}

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> clearBook(String bookId) async {}

  @override
  Future<int> clearInvalid(Set<String> validBookIds) async {
    clearInvalidCalls++;
    this.validBookIds = Set<String>.from(validBookIds);
    return 0;
  }

  @override
  Future<bool> has(String bookId, String chapterId) async => false;

  @override
  Future<Set<String>> listChapterIds(String bookId) async => <String>{};

  @override
  String sanitizeChapterId(String chapterId) => chapterId;

  @override
  Future<Map<String, int>> mapWordCounts(
    String bookId, {
    Set<String>? chapterIds,
  }) async => {};

  @override
  Future<({int bytes, int chapterFiles})> stats(String bookId) async =>
      (bytes: 0, chapterFiles: 0);
}

Book _book() => const Book(
  id: 'book-1',
  name: '测试书',
  author: '测试作者',
  coverUrl: 'cover-url',
  type: 'online',
  progress: 0.45,
  currentChapter: '第二章',
  lastChapter: '尾章',
  totalChapterNum: 1,
  durChapterIndex: 0,
  currentPageIndex: 65537,
  readConfig: BookReadConfig(reverseToc: true, extra: {'pageAnim': 2}),
  isFavorite: true,
  sourceUrl: 'book-url',
  tocUrl: 'toc-url',
  description: '简介',
  bookSourceUrl: 'source-url',
  group: '收藏',
  readIteration: 3,
);

List<Chapter> _chapters(String bookId) => [
  Chapter(
    id: 'chapter-0',
    bookId: bookId,
    title: '第一章',
    index: 0,
    url: 'chapter-0-url',
    content: '第一章正文',
  ),
  Chapter(
    id: 'chapter-1',
    bookId: bookId,
    title: '第二章',
    index: 1,
    url: 'chapter-1-url',
    content: '第二章正文',
  ),
  Chapter(
    id: 'chapter-2',
    bookId: bookId,
    title: '第三章',
    index: 2,
    url: 'chapter-2-url',
    content: '第三章正文',
  ),
];

BookProvider _provider(
  _ChapterMetaRepository repository, {
  BookshelfChangePort? bookshelfChangePort,
}) => BookProvider(
  repository: repository,
  sourceService: TestBookSourceService(),
  contentCache: _ChapterMetaCache(),
  bookshelfChangePort: bookshelfChangePort,
);

void _expectUnrelatedBookFieldsPreserved(Book book) {
  expect(book.id, 'book-1');
  expect(book.name, '测试书');
  expect(book.author, '测试作者');
  expect(book.coverUrl, 'cover-url');
  expect(book.type, 'online');
  expect(book.progress, 0.45);
  expect(book.currentPageIndex, 65537);
  expect(book.lastChapter, '尾章');
  expect(
    book.readConfig,
    const BookReadConfig(reverseToc: true, extra: {'pageAnim': 2}),
  );
  expect(book.isFavorite, isTrue);
  expect(book.sourceUrl, 'book-url');
  expect(book.tocUrl, 'toc-url');
  expect(book.description, '简介');
  expect(book.bookSourceUrl, 'source-url');
  expect(book.group, '收藏');
  expect(book.readIteration, 3);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('章节元数据刷新并同步书籍列表，保持页内位置和正文不变', () async {
    final originalBook = _book();
    final originalChapters = _chapters(originalBook.id);
    final repository = _ChapterMetaRepository(
      book: originalBook,
      chapters: originalChapters,
    );
    final cache = _ChapterMetaCache();
    final changes = BookshelfChangeBus();
    final provider = BookProvider(
      repository: repository,
      sourceService: TestBookSourceService(),
      contentCache: cache,
      bookshelfChangePort: changes,
    );
    addTearDown(changes.dispose);

    await provider.loadBooks(runMaintenance: false);
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.runStartupMaintenance();

    final updatedBook = provider.books.single;
    final meta = provider.shelfChapterMeta(originalBook.id);
    expect(meta?.count, 3);
    expect(meta?.durIndex, 1);
    expect(updatedBook.totalChapterNum, 3);
    expect(updatedBook.durChapterIndex, 1);
    _expectUnrelatedBookFieldsPreserved(updatedBook);
    expect(repository.insertedBooks, hasLength(1));
    expect(repository.insertedBooks.single, updatedBook);
    expect(repository.getAllCalls, 1);
    expect(repository.getChaptersCalls, 1);
    expect(repository.insertChaptersCalls, 0);
    expect(cache.clearInvalidCalls, 1);
    expect(cache.validBookIds, {originalBook.id});
    expect(notifications, 1);
    expect(repository.chaptersByBook[originalBook.id], originalChapters);
    expect(
      repository.chaptersByBook[originalBook.id]!.map(
        (chapter) => chapter.content,
      ),
      ['第一章正文', '第二章正文', '第三章正文'],
    );
    expect(changes.latest?.books, [updatedBook]);
  });

  test('章节元数据写入异常时后台任务隔离且不破坏书籍和章节状态', () async {
    final originalBook = _book();
    final originalChapters = _chapters(originalBook.id);
    final repository = _ChapterMetaRepository(
      book: originalBook,
      chapters: originalChapters,
    )..insertError = StateError('章节元数据写入失败');
    final provider = _provider(repository);

    await provider.loadBooks(runMaintenance: false);
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.runStartupMaintenance();

    expect(provider.books.single, originalBook);
    expect(repository.books.single, originalBook);
    expect(repository.insertedBooks, isEmpty);
    expect(repository.getAllCalls, 1);
    expect(repository.getChaptersCalls, 1);
    expect(repository.chaptersByBook[originalBook.id], originalChapters);
    expect(provider.shelfChapterMeta(originalBook.id)?.count, 3);
    expect(provider.shelfChapterMeta(originalBook.id)?.durIndex, 1);
    expect(notifications, 1);
  });

  test('章节读取期间的阅读进度更新不会被旧元数据快照覆盖', () async {
    final originalBook = _book();
    final repository =
        _ChapterMetaRepository(
            book: originalBook,
            chapters: _chapters(originalBook.id),
          )
          ..getChaptersStarted = Completer<void>()
          ..releaseGetChapters = Completer<void>();
    final provider = _provider(repository);

    await provider.loadBooks(runMaintenance: false);
    final maintenance = provider.runStartupMaintenance();
    await repository.getChaptersStarted!.future;

    await provider.updateProgress(
      originalBook.id,
      0.8,
      '第二章',
      pageIndex: 65537,
      durChapterIndex: 1,
    );
    repository.releaseGetChapters!.complete();
    await maintenance;

    final updated = provider.books.single;
    expect(updated.progress, 0.8);
    expect(updated.currentChapter, '第二章');
    expect(updated.currentPageIndex, 65537);
    expect(updated.durChapterIndex, 1);
    expect(updated.totalChapterNum, 3);
    expect(provider.shelfChapterMeta(originalBook.id), (count: 3, durIndex: 1));
  });
}
