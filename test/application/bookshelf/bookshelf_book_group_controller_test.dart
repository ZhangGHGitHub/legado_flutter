import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_book_group_controller.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';

final class _FakeBookRepository implements BookRepository {
  _FakeBookRepository(Iterable<Book> initialBooks)
    : books = List<Book>.of(initialBooks);

  final List<Book> books;
  final List<String> calls = [];
  Object? updateError;
  Object? getAllError;

  @override
  Future<void> updateGroup(String bookId, String group) async {
    calls.add('updateGroup:$bookId:$group');
    final error = updateError;
    if (error != null) throw error;

    final index = books.indexWhere((book) => book.id == bookId);
    if (index >= 0) {
      books[index] = books[index].copyWith(group: group);
    }
  }

  @override
  Future<List<Book>> getAll() async {
    calls.add('getAll');
    final error = getAllError;
    if (error != null) throw error;
    return List<Book>.unmodifiable(books);
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

Book _book(String id, String group) =>
    Book(id: id, name: id, author: '作者', type: 'local', group: group);

void main() {
  test('单本分组先写入再刷新书架', () async {
    final repository = _FakeBookRepository([_book('book-1', '旧分组')]);
    final controller = BookshelfBookGroupController(repository: repository);

    final books = await controller.updateBookGroup('book-1', '新分组');

    expect(repository.calls, ['updateGroup:book-1:新分组', 'getAll']);
    expect(books.single.group, '新分组');
  });

  test('批量分组按输入顺序逐本写入后刷新书架', () async {
    final repository = _FakeBookRepository([
      _book('book-1', '旧分组'),
      _book('book-2', '旧分组'),
    ]);
    final controller = BookshelfBookGroupController(repository: repository);

    final books = await controller.updateBooksGroup([
      'book-2',
      'book-1',
    ], '新分组');

    expect(repository.calls, [
      'updateGroup:book-2:新分组',
      'updateGroup:book-1:新分组',
      'getAll',
    ]);
    expect(books.map((book) => book.group), ['新分组', '新分组']);
  });

  test('空批量不写入但仍刷新书架', () async {
    final repository = _FakeBookRepository([_book('book-1', '原分组')]);
    final controller = BookshelfBookGroupController(repository: repository);

    final books = await controller.updateBooksGroup(const [], '新分组');

    expect(repository.calls, ['getAll']);
    expect(books.single.group, '原分组');
  });

  test('repository 写入异常原样传播且不会继续刷新或写后续项目', () async {
    final error = StateError('分组写入失败');
    final repository = _FakeBookRepository([
      _book('book-1', '旧分组'),
      _book('book-2', '旧分组'),
    ])..updateError = error;
    final controller = BookshelfBookGroupController(repository: repository);

    await expectLater(
      controller.updateBooksGroup(['book-1', 'book-2'], '新分组'),
      throwsA(same(error)),
    );

    expect(repository.calls, ['updateGroup:book-1:新分组']);
  });

  test('repository 刷新异常原样传播', () async {
    final error = StateError('书架刷新失败');
    final repository = _FakeBookRepository([_book('book-1', '旧分组')])
      ..getAllError = error;
    final controller = BookshelfBookGroupController(repository: repository);

    await expectLater(
      controller.updateBookGroup('book-1', '新分组'),
      throwsA(same(error)),
    );

    expect(repository.calls, ['updateGroup:book-1:新分组', 'getAll']);
  });
}
