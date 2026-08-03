import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_book_lifecycle_controller.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';

final class _RecordingRepository implements BookRepository {
  final List<String> calls = [];

  @override
  Future<void> insert(Book book) async => calls.add('insert:${book.id}');

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
  Future<void> delete(String bookId) async => calls.add('delete:$bookId');

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

final class _RecordingCache implements ChapterContentCachePort {
  _RecordingCache(this.repository);

  final _RecordingRepository repository;

  @override
  Future<String?> get(String bookId, String chapterId) async => null;

  @override
  Future<void> save(String bookId, String chapterId, String content) async {}

  @override
  Future<void> delete(String bookId, String chapterId) async {}

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> clearBook(String bookId) async =>
      repository.calls.add('clearBook:$bookId');

  @override
  Future<int> clearInvalid(Set<String> validBookIds) async => 0;

  @override
  Future<bool> has(String bookId, String chapterId) async => false;

  @override
  Future<Set<String>> listChapterIds(String bookId) async => {};

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

Book _book(String id) => Book(id: id, name: id);

void main() {
  test('新增书籍只写入仓储', () async {
    final repository = _RecordingRepository();
    final controller = BookshelfBookLifecycleController(
      repository: repository,
      contentCache: _RecordingCache(repository),
    );

    await controller.addBook(_book('book-1'));

    expect(repository.calls, ['insert:book-1']);
  });

  test('删除书籍先删除仓储记录再清理章节缓存', () async {
    final repository = _RecordingRepository();
    final controller = BookshelfBookLifecycleController(
      repository: repository,
      contentCache: _RecordingCache(repository),
    );

    await controller.removeBook('book-1');

    expect(repository.calls, ['delete:book-1', 'clearBook:book-1']);
  });
}
