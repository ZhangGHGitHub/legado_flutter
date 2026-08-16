import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/book_progress_controller.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';

final class _ProgressCall {
  const _ProgressCall({
    required this.bookId,
    required this.progress,
    required this.chapter,
    required this.pageIndex,
  });

  final String bookId;
  final double progress;
  final String? chapter;
  final int pageIndex;
}

final class _RecordingRepository implements BookRepository {
  Object? insertError;
  Object? updateProgressError;
  final List<Book> inserted = [];
  final List<_ProgressCall> progressCalls = [];

  @override
  Future<void> insert(Book book) async {
    if (insertError case final error?) {
      throw error;
    }
    inserted.add(book);
  }

  @override
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
  }) async {
    if (updateProgressError case final error?) {
      throw error;
    }
    progressCalls.add(
      _ProgressCall(
        bookId: bookId,
        progress: progress,
        chapter: chapter,
        pageIndex: pageIndex,
      ),
    );
  }

  @override
  Future<List<Book>> getAll() async => const [];

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

Book _existingBook() => const Book(
  id: 'book-1',
  name: '测试书',
  author: '测试作者',
  coverUrl: 'https://example.com/cover.jpg',
  type: 'audio',
  progress: 0.25,
  currentChapter: '第七章',
  lastChapter: '第九十九章',
  totalChapterNum: 99,
  durChapterIndex: 6,
  currentPageIndex: 12,
  readConfig: BookReadConfig(reverseToc: true, extra: {'pageAnim': 2}),
  isFavorite: true,
  sourceUrl: 'book://source',
  tocUrl: 'book://toc',
  description: '简介',
  bookSourceUrl: 'source://origin',
  group: '收藏',
  readIteration: 3,
  simReadEnabled: true,
  simReadStartDate: '2026-08-03',
  simReadStartChapter: 4,
  simReadDailyChapters: 8,
  updatedAt: '2026-08-03T12:00:00Z',
);

void main() {
  test('durChapterIndex 非空且有 existingBook 时 insert 复制后的整书记录', () async {
    final repository = _RecordingRepository();
    final controller = BookProgressController(repository: repository);

    final result = await controller.updateProgress(
      'book-1',
      0.5,
      '第八章',
      pageIndex: 21,
      durChapterIndex: 7,
      existingBook: _existingBook(),
    );

    expect(repository.inserted, hasLength(1));
    expect(repository.progressCalls, isEmpty);
    expect(result.didUpsertBook, isTrue);
    expect(result.upsertedBook, same(repository.inserted.single));
  });

  test('durChapterIndex 非空但 existingBook 为空时调用 updateProgress', () async {
    final repository = _RecordingRepository();
    final controller = BookProgressController(repository: repository);

    final result = await controller.updateProgress(
      'book-1',
      0.5,
      '第八章',
      pageIndex: 21,
      durChapterIndex: 7,
    );

    expect(repository.inserted, isEmpty);
    expect(repository.progressCalls, hasLength(1));
    expect(repository.progressCalls.single.bookId, 'book-1');
    expect(result.didUpsertBook, isFalse);
    expect(result.upsertedBook, isNull);
  });

  test('bookId 与 existingBook 不一致时不得 upsert 错误书籍', () async {
    final repository = _RecordingRepository();
    final controller = BookProgressController(repository: repository);

    final result = await controller.updateProgress(
      'book-2',
      0.5,
      '第八章',
      pageIndex: 21,
      durChapterIndex: 7,
      existingBook: _existingBook(),
    );

    expect(repository.inserted, isEmpty);
    expect(repository.progressCalls, hasLength(1));
    expect(repository.progressCalls.single.bookId, 'book-2');
    expect(result.didUpsertBook, isFalse);
    expect(result.upsertedBook, isNull);
  });

  test('durChapterIndex 为空时调用 updateProgress', () async {
    final repository = _RecordingRepository();
    final controller = BookProgressController(repository: repository);

    await controller.updateProgress(
      'book-1',
      0.75,
      '第九章',
      existingBook: _existingBook(),
    );

    expect(repository.inserted, isEmpty);
    expect(repository.progressCalls, hasLength(1));
    expect(repository.progressCalls.single.progress, 0.75);
    expect(repository.progressCalls.single.chapter, '第九章');
  });

  test('upsert 分支只更新阅读进度字段并保留其他整书字段', () async {
    final repository = _RecordingRepository();
    final controller = BookProgressController(repository: repository);
    final existingBook = _existingBook();

    final result = await controller.updateProgress(
      existingBook.id,
      0.875,
      '第十章',
      pageIndex: 34,
      durChapterIndex: 9,
      existingBook: existingBook,
    );

    expect(
      result.upsertedBook,
      existingBook.copyWith(
        progress: 0.875,
        currentChapter: '第十章',
        currentPageIndex: 34,
        durChapterIndex: 9,
      ),
    );
    expect(result.upsertedBook?.currentPageIndex, 34);
    expect(result.upsertedBook?.durChapterIndex, 9);
    expect(result.upsertedBook?.currentChapter, '第十章');
  });

  test('pageIndex 原样传递给 repository.updateProgress', () async {
    final repository = _RecordingRepository();
    final controller = BookProgressController(repository: repository);

    await controller.updateProgress('book-1', 0.5, '第八章', pageIndex: 65537);

    expect(repository.progressCalls.single.pageIndex, 65537);
  });

  test('insert 异常原样传播', () async {
    final error = StateError('insert failed');
    final repository = _RecordingRepository()..insertError = error;
    final controller = BookProgressController(repository: repository);

    await expectLater(
      controller.updateProgress(
        'book-1',
        0.5,
        '第八章',
        durChapterIndex: 7,
        existingBook: _existingBook(),
      ),
      throwsA(same(error)),
    );
  });

  test('updateProgress 异常原样传播', () async {
    final error = StateError('update failed');
    final repository = _RecordingRepository()..updateProgressError = error;
    final controller = BookProgressController(repository: repository);

    await expectLater(
      controller.updateProgress('book-1', 0.5, '第八章', pageIndex: 21),
      throwsA(same(error)),
    );
  });
}
