import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/book_record_controller.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';

final class _RecordingRepository implements BookRepository {
  Book? inserted;

  @override
  Future<void> insert(Book book) async => inserted = book;

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
  Future<List<Chapter>> getChapters(String bookId) async => const [];

  @override
  Future<String?> getChapterContent(String chapterId) async => null;

  @override
  Future<void> saveChapterContent(String chapterId, String content) async {}

  @override
  Future<void> clearChapterContent(Chapter chapter) async {}
}

Book _book() => Book(
  id: 'book-1',
  name: '测试书',
  currentChapter: '第八章',
  durChapterIndex: 7,
  currentPageIndex: 11,
  progress: 0.4,
  readIteration: 1,
  simReadStartChapter: 2,
  simReadDailyChapters: 5,
);

void main() {
  test('更新读完轮次只改变轮次并保留阅读位置', () async {
    final repository = _RecordingRepository();
    final controller = BookRecordController(repository: repository);

    final next = await controller.updateReadIteration(_book(), 3);

    expect(next.readIteration, 3);
    expect(next.durChapterIndex, 7);
    expect(next.currentPageIndex, 11);
    expect(next.currentChapter, '第八章');
    expect(repository.inserted, same(next));
  });

  test('模拟追读字段按原边界裁剪且不改变阅读位置', () async {
    final repository = _RecordingRepository();
    final controller = BookRecordController(repository: repository);

    final next = await controller.updateSimulatedReading(
      _book(),
      enabled: true,
      startDate: '2026-08-03',
      startChapter: -2,
      dailyChapters: 0,
    );

    expect(next.simReadEnabled, isTrue);
    expect(next.simReadStartDate, '2026-08-03');
    expect(next.simReadStartChapter, 0);
    expect(next.simReadDailyChapters, 3);
    expect(next.durChapterIndex, 7);
    expect(next.currentPageIndex, 11);
    expect(repository.inserted, same(next));
  });
}
