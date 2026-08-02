import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_notifier.dart';
import 'package:legado_flutter/domain/book/book.dart';

void main() {
  group('BookshelfState', () {
    test('preserves the four factory state projections', () {
      final initial = BookshelfState.initial();
      expect(initial.status, BookshelfStatus.initial);
      expect(initial.books, isEmpty);
      expect(initial.isInitialLoading, isFalse);
      expect(initial.isLoading, isFalse);
      expect(initial.hasValue, isFalse);
      expect(initial.hasError, isFalse);
      expect(initial.isRefreshing, isFalse);
      expect(initial.error, isNull);
      expect(initial.stackTrace, isNull);

      final loading = BookshelfState.loading();
      expect(loading.status, BookshelfStatus.loading);
      expect(loading.isInitialLoading, isTrue);
      expect(loading.isLoading, isTrue);
      expect(loading.hasValue, isFalse);
      expect(loading.hasError, isFalse);
      expect(loading.isRefreshing, isFalse);

      final refreshing = BookshelfState.loading(isRefreshing: true);
      expect(refreshing.status, BookshelfStatus.loading);
      expect(refreshing.isInitialLoading, isFalse);
      expect(refreshing.isLoading, isTrue);
      expect(refreshing.isRefreshing, isTrue);

      final book = Book(id: 'book-1', name: '示例书');
      final success = BookshelfState.success([book]);
      expect(success.status, BookshelfStatus.success);
      expect(success.books, [book]);
      expect(success.hasValue, isTrue);
      expect(success.isLoading, isFalse);
      expect(success.hasError, isFalse);

      final error = StateError('database unavailable');
      final stackTrace = StackTrace.current;
      final failure = BookshelfState.failure(error, stackTrace, books: [book]);
      expect(failure.status, BookshelfStatus.failure);
      expect(failure.books, [book]);
      expect(failure.hasError, isTrue);
      expect(failure.error, same(error));
      expect(failure.stackTrace, same(stackTrace));
      expect(failure.isLoading, isFalse);
    });

    test('has Freezed value semantics and a read-only book list', () {
      final book = Book(id: 'book-1', name: '示例书');
      final input = <Book>[book];
      final state = BookshelfState.success(input);

      input.add(Book(id: 'book-2', name: '不会进入状态的书'));

      expect(state, BookshelfState.success([book]));
      expect(state.copyWith(isRefreshing: true).isRefreshing, isTrue);
      expect(state.books, hasLength(1));
      expect(
        () => state.books.add(Book(id: 'book-3', name: '不可写入')),
        throwsUnsupportedError,
      );
    });
  });
}
