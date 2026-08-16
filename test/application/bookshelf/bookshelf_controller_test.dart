import 'package:flutter_test/flutter_test.dart';

import 'package:legado_flutter/application/bookshelf/bookshelf_controller.dart';
import 'package:legado_flutter/application/core_api.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';
import 'package:legado_flutter/domain/search_result_item.dart';

void main() {
  final books = [const Book(id: 'book-1', name: '示例书籍', author: '示例作者')];

  group('RepositoryBookshelfPort', () {
    test('delegates to BookRepository.getAll and preserves the list', () async {
      final repository = _FakeBookRepository(books);
      final port = RepositoryBookshelfPort(repository);

      final result = await port.loadBookshelf();

      expect(repository.getAllCalls, 1);
      expect(result, same(books));
    });

    test('propagates repository errors unchanged', () async {
      final error = StateError('repository failed');
      final repository = _FakeBookRepository(books, error: error);

      expect(
        RepositoryBookshelfPort(repository).loadBookshelf(),
        throwsA(same(error)),
      );
    });
  });

  group('CoreApiBookshelfPort', () {
    test('delegates to CoreApi.getBookshelf and preserves the list', () async {
      final coreApi = _FakeCoreApi(books);
      final port = CoreApiBookshelfPort(coreApi);

      final result = await port.loadBookshelf();

      expect(coreApi.getBookshelfCalls, 1);
      expect(result, same(books));
    });

    test('propagates CoreApi errors unchanged', () async {
      final error = StateError('core api failed');
      final coreApi = _FakeCoreApi(books, error: error);

      expect(
        CoreApiBookshelfPort(coreApi).loadBookshelf(),
        throwsA(same(error)),
      );
    });
  });

  group('BookshelfController', () {
    test(
      'delegates to the supplied BookshelfPort and preserves the list',
      () async {
        final port = _FakeBookshelfPort(books);
        final controller = BookshelfController(port);

        final result = await controller.loadBookshelf();

        expect(port.loadBookshelfCalls, 1);
        expect(result, same(books));
      },
    );

    test('propagates port errors unchanged', () async {
      final error = StateError('port failed');
      final port = _FakeBookshelfPort(books, error: error);

      expect(controllerFor(port).loadBookshelf(), throwsA(same(error)));
    });
  });
}

BookshelfController controllerFor(BookshelfPort port) =>
    BookshelfController(port);

class _FakeBookshelfPort implements BookshelfPort {
  _FakeBookshelfPort(this.books, {this.error});

  final List<Book> books;
  final Object? error;
  int loadBookshelfCalls = 0;

  @override
  Future<List<Book>> loadBookshelf() async {
    loadBookshelfCalls++;
    if (error != null) {
      throw error!;
    }
    return books;
  }
}

class _FakeBookRepository implements BookRepository {
  _FakeBookRepository(this.books, {this.error});

  final List<Book> books;
  final Object? error;
  int getAllCalls = 0;

  @override
  Future<List<Book>> getAll() async {
    getAllCalls++;
    if (error != null) {
      throw error!;
    }
    return books;
  }

  @override
  Future<void> clearChapterContent(Chapter chapter) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String bookId) => throw UnimplementedError();

  @override
  Future<List<Chapter>> getChapters(String bookId) =>
      throw UnimplementedError();

  @override
  Future<String?> getChapterContent(String chapterId) =>
      throw UnimplementedError();

  @override
  Future<void> insert(Book book) => throw UnimplementedError();

  @override
  Future<void> insertChapters(List<Chapter> chapters) =>
      throw UnimplementedError();

  @override
  Future<void> saveChapterContent(String chapterId, String content) =>
      throw UnimplementedError();

  @override
  Future<void> updateCover(String bookId, String coverUrl) =>
      throw UnimplementedError();

  @override
  Future<void> updateBookDetails(
    String bookId,
    String name,
    String author,
    String description,
  ) async {}

  @override
  Future<void> updateGroup(String bookId, String group) =>
      throw UnimplementedError();

  @override
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
  }) => throw UnimplementedError();
}

class _FakeCoreApi implements CoreApi {
  _FakeCoreApi(this.books, {this.error});

  final List<Book> books;
  final Object? error;
  int getBookshelfCalls = 0;

  @override
  Future<List<Book>> getBookshelf() async {
    getBookshelfCalls++;
    if (error != null) {
      throw error!;
    }
    return books;
  }

  @override
  Future<List<SearchResultItem>> searchBooks({
    required String sourceUrl,
    required String keyword,
  }) => throw UnimplementedError();
}
