import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_change_port.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_controller.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/providers/book_provider.dart';

import '../helpers/book_source_service_test_factory.dart';

void main() {
  test(
    'loadBooks delegates the bookshelf read through the controller',
    () async {
      final books = [const Book(id: 'book-1', name: '示例书籍', author: '示例作者')];
      final controller = _RecordingBookshelfController(books);
      final provider = BookProvider(
        repository: _EmptyBookDao(),
        contentCache: const FileChapterContentCache(),
        sourceService: TestBookSourceService(),
        bookshelfController: controller,
      );
      final notifications = <bool>[];
      provider.addListener(() => notifications.add(provider.isLoading));

      await provider.loadBooks(runMaintenance: false);

      expect(controller.calls, 1);
      expect(provider.books, same(books));
      expect(provider.isLoading, isFalse);
      expect(provider.loadError, isNull);
      expect(notifications, [true, false]);
    },
  );

  test(
    'loadBooks preserves the legacy error text through the controller',
    () async {
      final error = StateError('bookshelf read failed');
      final changes = BookshelfChangeBus();
      addTearDown(changes.dispose);
      final provider = BookProvider(
        repository: _EmptyBookDao(),
        contentCache: const FileChapterContentCache(),
        sourceService: TestBookSourceService(),
        bookshelfController: _RecordingBookshelfController(
          const [],
          error: error,
        ),
        bookshelfChangePort: changes,
      );

      await provider.loadBooks(runMaintenance: false);

      expect(provider.books, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.loadError, '加载书架失败: $error');
      expect(changes.latest?.error, provider.loadError);
      expect(changes.latest?.books, isEmpty);
    },
  );
}

class _RecordingBookshelfController extends BookshelfController {
  _RecordingBookshelfController(this.books, {this.error})
    : super(_NoopBookshelfPort());

  final List<Book> books;
  final Object? error;
  int calls = 0;

  @override
  Future<List<Book>> loadBookshelf() async {
    calls++;
    if (error != null) throw error!;
    return books;
  }
}

class _NoopBookshelfPort implements BookshelfPort {
  @override
  Future<List<Book>> loadBookshelf() async => const [];
}

class _EmptyBookDao extends BookDao {
  @override
  Future<List<Book>> getAll() async => const [];

  @override
  Future<List<Chapter>> getChapters(String bookId) async => const [];
}
