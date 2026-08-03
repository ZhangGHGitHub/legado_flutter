import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_chapter_meta_controller.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';

final class _RecordingRepository implements BookRepository {
  _RecordingRepository(this.chapters);

  final List<Chapter> chapters;
  final List<String> calls = [];
  final List<Book> insertedBooks = [];
  Object? getChaptersError;
  Object? insertError;

  @override
  Future<void> insert(Book book) async {
    calls.add('insert:${book.id}');
    final error = insertError;
    if (error != null) throw error;
    insertedBooks.add(book);
  }

  @override
  Future<List<Book>> getAll() async => const [];

  @override
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
  }) async {}

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
  Future<List<Chapter>> getChapters(String bookId) async {
    calls.add('getChapters:$bookId');
    final error = getChaptersError;
    if (error != null) throw error;
    return List<Chapter>.of(chapters);
  }

  @override
  Future<String?> getChapterContent(String chapterId) async => null;

  @override
  Future<void> saveChapterContent(String chapterId, String content) async {}

  @override
  Future<void> clearChapterContent(Chapter chapter) async {}
}

Chapter _chapter(String bookId, int index, String title) => Chapter(
  id: '$bookId-$index',
  bookId: bookId,
  title: title,
  index: index,
  url: '$bookId-url-$index',
);

Book _book({int totalChapterNum = 0, int durChapterIndex = 0}) => Book(
  id: 'book-1',
  name: '书名',
  author: '作者',
  coverUrl: 'cover',
  type: 'online',
  progress: 0.625,
  currentChapter: '第二章',
  lastChapter: '第三章',
  totalChapterNum: totalChapterNum,
  durChapterIndex: durChapterIndex,
  currentPageIndex: 65537,
  readConfig: BookReadConfig(reverseToc: true, extra: {'fontSize': 18}),
  isFavorite: true,
  sourceUrl: 'book-url',
  tocUrl: 'toc-url',
  description: '简介',
  bookSourceUrl: 'source-url',
  group: '分组',
  readIteration: 4,
  simReadEnabled: true,
  simReadStartDate: '2026-08-03',
  simReadStartChapter: 2,
  simReadDailyChapters: 5,
  updatedAt: '2026-08-03T00:00:00Z',
);

void main() {
  test('读取章节并返回数量和当前章节下标，元数据不变时不写入', () async {
    final repository = _RecordingRepository([
      _chapter('book-1', 0, '第一章'),
      _chapter('book-1', 1, '第二章'),
      _chapter('book-1', 2, '第三章'),
    ]);
    final controller = BookshelfChapterMetaController(repository: repository);

    final result = await controller.refresh(
      _book(totalChapterNum: 3, durChapterIndex: 1),
    );

    expect(result.totalChapterNum, 3);
    expect(result.chapterCount, 3);
    expect(result.durChapterIndex, 1);
    expect(result.didUpdate, isFalse);
    expect(result.updatedBook, isNull);
    expect(repository.calls, ['getChapters:book-1']);
    expect(repository.insertedBooks, isEmpty);
  });

  test('章节数量或当前章节下标变化时只更新元数据并保留其他字段', () async {
    final repository = _RecordingRepository([
      _chapter('book-1', 0, '第一章'),
      _chapter('book-1', 1, '第二章'),
    ]);
    final controller = BookshelfChapterMetaController(repository: repository);
    final book = _book(totalChapterNum: 1, durChapterIndex: 0);

    final result = await controller.refresh(book);

    final updated = result.updatedBook;
    expect(result.didUpdate, isTrue);
    expect(updated, isNotNull);
    expect(updated, book.copyWith(totalChapterNum: 2, durChapterIndex: 1));
    expect(updated!.currentPageIndex, book.currentPageIndex);
    expect(updated.progress, book.progress);
    expect(updated.currentChapter, book.currentChapter);
    expect(updated.readConfig, book.readConfig);
    expect(updated.group, book.group);
    expect(repository.calls, ['getChapters:book-1', 'insert:book-1']);
  });

  test('当前章节不匹配时不猜测下标，但仍可更新章节数量', () async {
    final repository = _RecordingRepository([
      _chapter('book-1', 0, '第一章'),
      _chapter('book-1', 1, '第二章'),
    ]);
    final controller = BookshelfChapterMetaController(repository: repository);
    final book = _book(
      totalChapterNum: 1,
      durChapterIndex: 7,
    ).copyWith(currentChapter: '不存在的章节');

    final result = await controller.refresh(book);

    expect(result.durChapterIndex, isNull);
    expect(result.updatedBook, book.copyWith(totalChapterNum: 2));
    expect(result.updatedBook!.durChapterIndex, 7);
    expect(repository.insertedBooks, hasLength(1));
  });

  test('空章节不清除已持久化的元数据', () async {
    final repository = _RecordingRepository(const []);
    final controller = BookshelfChapterMetaController(repository: repository);

    final result = await controller.refresh(_book(totalChapterNum: 3));

    expect(result.totalChapterNum, 0);
    expect(result.durChapterIndex, isNull);
    expect(result.updatedBook, isNull);
    expect(repository.calls, ['getChapters:book-1']);
    expect(repository.insertedBooks, isEmpty);
  });

  test('读取或写入异常原样传播', () async {
    final readError = StateError('章节读取失败');
    final readRepository = _RecordingRepository(const [])
      ..getChaptersError = readError;
    final controller = BookshelfChapterMetaController(
      repository: readRepository,
    );

    await expectLater(controller.refresh(_book()), throwsA(same(readError)));

    final writeError = StateError('书籍写入失败');
    final writeRepository = _RecordingRepository([_chapter('book-1', 0, '第一章')])
      ..insertError = writeError;
    final writeController = BookshelfChapterMetaController(
      repository: writeRepository,
    );

    await expectLater(
      writeController.refresh(_book(totalChapterNum: 0)),
      throwsA(same(writeError)),
    );
  });
}
