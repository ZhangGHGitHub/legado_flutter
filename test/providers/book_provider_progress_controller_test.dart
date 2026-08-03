import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/providers/book_provider.dart';

import '../helpers/book_source_service_test_factory.dart';

final class _ProgressRepository extends BookDao {
  _ProgressRepository(Book book) : storedBook = book;

  Book storedBook;
  Book? insertedBook;
  Object? insertError;
  Object? updateError;
  int getAllCalls = 0;
  int getChaptersCalls = 0;
  int updateProgressCalls = 0;
  String? updatedBookId;
  double? updatedProgress;
  String? updatedChapter;
  int? updatedPageIndex;

  @override
  Future<void> insert(Book book) async {
    if (insertError case final error?) throw error;
    insertedBook = book;
    storedBook = book;
  }

  @override
  Future<List<Book>> getAll() async {
    getAllCalls++;
    return [storedBook];
  }

  @override
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
  }) async {
    updateProgressCalls++;
    updatedBookId = bookId;
    updatedProgress = progress;
    updatedChapter = chapter;
    updatedPageIndex = pageIndex;
    if (updateError case final error?) throw error;
    storedBook = storedBook.copyWith(
      progress: progress,
      currentChapter: chapter,
      currentPageIndex: pageIndex,
    );
  }

  @override
  Future<List<Chapter>> getChapters(String bookId) async {
    getChaptersCalls++;
    return [
      Chapter(
        id: 'chapter-0',
        bookId: bookId,
        title: '第一章',
        index: 0,
        url: '/chapter-0',
      ),
      Chapter(
        id: 'chapter-1',
        bookId: bookId,
        title: '第二章',
        index: 1,
        url: '/chapter-1',
      ),
    ];
  }
}

Book _book() => const Book(
  id: 'book-1',
  name: '测试书',
  author: '原作者',
  coverUrl: 'original-cover',
  progress: 0.1,
  currentChapter: '第一章',
  lastChapter: '尾章',
  totalChapterNum: 2,
  durChapterIndex: 0,
  currentPageIndex: 3,
  sourceUrl: 'book-url',
  tocUrl: 'toc-url',
  description: '原简介',
  bookSourceUrl: 'source-url',
  group: '原分组',
  readIteration: 2,
);

BookProvider _provider(_ProgressRepository repository) => BookProvider(
  repository: repository,
  sourceService: TestBookSourceService(),
  contentCache: const FileChapterContentCache(),
);

void _expectUnrelatedFieldsPreserved(Book book) {
  expect(book.name, '测试书');
  expect(book.author, '原作者');
  expect(book.coverUrl, 'original-cover');
  expect(book.lastChapter, '尾章');
  expect(book.totalChapterNum, 2);
  expect(book.sourceUrl, 'book-url');
  expect(book.tocUrl, 'toc-url');
  expect(book.description, '原简介');
  expect(book.bookSourceUrl, 'source-url');
  expect(book.group, '原分组');
  expect(book.readIteration, 2);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('有章节索引时整书 upsert 并刷新书架、章节元数据且只通知一次', () async {
    final repository = _ProgressRepository(_book());
    final provider = _provider(repository);
    await provider.loadBooks(runMaintenance: false);
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.updateProgress(
      'book-1',
      0.75,
      '第二章',
      pageIndex: 13,
      durChapterIndex: 1,
    );

    expect(repository.updateProgressCalls, 0);
    expect(repository.insertedBook, isNotNull);
    expect(repository.insertedBook?.progress, 0.75);
    expect(repository.insertedBook?.currentChapter, '第二章');
    expect(repository.insertedBook?.currentPageIndex, 13);
    expect(repository.insertedBook?.durChapterIndex, 1);
    _expectUnrelatedFieldsPreserved(repository.insertedBook!);
    expect(provider.books.single, repository.insertedBook);
    expect(repository.getAllCalls, 2);
    expect(repository.getChaptersCalls, 1);
    expect(notifications, 1);
  });

  test('无章节索引时局部更新原样传递 pageIndex 并只更新阅读位置字段', () async {
    final repository = _ProgressRepository(_book());
    final provider = _provider(repository);
    await provider.loadBooks(runMaintenance: false);
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.updateProgress('book-1', 0.5, '第一章', pageIndex: 65537);

    expect(repository.insertedBook, isNull);
    expect(repository.updateProgressCalls, 1);
    expect(repository.updatedBookId, 'book-1');
    expect(repository.updatedProgress, 0.5);
    expect(repository.updatedChapter, '第一章');
    expect(repository.updatedPageIndex, 65537);
    expect(repository.storedBook.progress, 0.5);
    expect(repository.storedBook.currentChapter, '第一章');
    expect(repository.storedBook.currentPageIndex, 65537);
    expect(repository.storedBook.durChapterIndex, 0);
    _expectUnrelatedFieldsPreserved(repository.storedBook);
    expect(provider.books.single, repository.storedBook);
    expect(repository.getAllCalls, 2);
    expect(repository.getChaptersCalls, 1);
    expect(notifications, 1);
  });

  test('整书 upsert 异常原样传播且不刷新或通知', () async {
    final error = StateError('整书写入失败');
    final repository = _ProgressRepository(_book())..insertError = error;
    final provider = _provider(repository);
    await provider.loadBooks(runMaintenance: false);
    var notifications = 0;
    provider.addListener(() => notifications++);

    await expectLater(
      provider.updateProgress(
        'book-1',
        0.75,
        '第二章',
        pageIndex: 13,
        durChapterIndex: 1,
      ),
      throwsA(same(error)),
    );

    expect(repository.updateProgressCalls, 0);
    expect(repository.getAllCalls, 1);
    expect(repository.getChaptersCalls, 0);
    expect(provider.books.single, _book());
    expect(notifications, 0);
  });

  test('局部进度更新异常原样传播且不刷新或通知', () async {
    final error = StateError('局部写入失败');
    final repository = _ProgressRepository(_book())..updateError = error;
    final provider = _provider(repository);
    await provider.loadBooks(runMaintenance: false);
    var notifications = 0;
    provider.addListener(() => notifications++);

    await expectLater(
      provider.updateProgress('book-1', 0.5, '第一章', pageIndex: 65537),
      throwsA(same(error)),
    );

    expect(repository.updateProgressCalls, 1);
    expect(repository.updatedPageIndex, 65537);
    expect(repository.getAllCalls, 1);
    expect(repository.getChaptersCalls, 0);
    expect(provider.books.single, _book());
    expect(notifications, 0);
  });
}
