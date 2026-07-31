import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_notifier.dart';
import 'package:legado_flutter/application/core_api.dart';
import 'package:legado_flutter/application/core_api_provider.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/search_result_item.dart';

void main() {
  group('BookshelfNotifier', () {
    test('starts in the initial state', () {
      final container = ProviderContainer(
        overrides: [coreApiProvider.overrideWithValue(_FakeCoreApi())],
      );
      addTearDown(container.dispose);

      final state = container.read(bookshelfNotifierProvider);

      expect(state.status, BookshelfStatus.initial);
      expect(state.books, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.hasValue, isFalse);
      expect(state.hasError, isFalse);
    });

    test(
      'publishes loading and then success when loading the bookshelf',
      () async {
        final api = _FakeCoreApi();
        final container = ProviderContainer(
          overrides: [coreApiProvider.overrideWithValue(api)],
        );
        addTearDown(container.dispose);
        final notifier = container.read(bookshelfNotifierProvider.notifier);
        final book = Book(id: 'book-1', name: '示例书');

        final load = notifier.load();

        expect(
          container.read(bookshelfNotifierProvider).status,
          BookshelfStatus.loading,
        );
        expect(
          container.read(bookshelfNotifierProvider).isInitialLoading,
          isTrue,
        );
        expect(api.getBookshelfCalls, 1);

        api.completeNext([book]);
        await load;

        final state = container.read(bookshelfNotifierProvider);
        expect(state.status, BookshelfStatus.success);
        expect(state.books.single, same(book));
        expect(state.isRefreshing, isFalse);
        expect(state.error, isNull);
      },
    );

    test('publishes the original error and stack trace on failure', () async {
      final api = _FakeCoreApi();
      final container = ProviderContainer(
        overrides: [coreApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(bookshelfNotifierProvider.notifier);
      final error = StateError('database unavailable');
      final stackTrace = StackTrace.current;

      final load = notifier.load();
      api.failNext(error, stackTrace);
      await load;

      final state = container.read(bookshelfNotifierProvider);
      expect(state.status, BookshelfStatus.failure);
      expect(state.hasError, isTrue);
      expect(state.error, same(error));
      expect(state.stackTrace, same(stackTrace));
      expect(state.books, isEmpty);
    });

    test(
      'refresh keeps old books while loading and replaces them on success',
      () async {
        final api = _FakeCoreApi();
        final container = ProviderContainer(
          overrides: [coreApiProvider.overrideWithValue(api)],
        );
        addTearDown(container.dispose);
        final notifier = container.read(bookshelfNotifierProvider.notifier);
        final oldBook = Book(id: 'old', name: '旧书');
        final newBook = Book(id: 'new', name: '新书');

        final initialLoad = notifier.load();
        api.completeNext([oldBook]);
        await initialLoad;

        final refresh = notifier.refresh();
        final refreshingState = container.read(bookshelfNotifierProvider);
        expect(refreshingState.status, BookshelfStatus.loading);
        expect(refreshingState.isRefreshing, isTrue);
        expect(refreshingState.books.single, same(oldBook));
        expect(refreshingState.isInitialLoading, isFalse);

        api.completeNext([newBook]);
        await refresh;

        final state = container.read(bookshelfNotifierProvider);
        expect(state.status, BookshelfStatus.success);
        expect(state.books.single, same(newBook));
        expect(state.isRefreshing, isFalse);
      },
    );

    test('keeps old books when a refresh fails', () async {
      final api = _FakeCoreApi();
      final container = ProviderContainer(
        overrides: [coreApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(bookshelfNotifierProvider.notifier);
      final oldBook = Book(id: 'old', name: '旧书');
      final error = StateError('network unavailable');

      final initialLoad = notifier.load();
      api.completeNext([oldBook]);
      await initialLoad;

      final refresh = notifier.refresh();
      api.failNext(error, StackTrace.current);
      await refresh;

      final state = container.read(bookshelfNotifierProvider);
      expect(state.status, BookshelfStatus.failure);
      expect(state.error, same(error));
      expect(state.books.single, same(oldBook));
      expect(state.isRefreshing, isFalse);
    });

    test('ignores a stale request after a newer request completes', () async {
      final api = _FakeCoreApi();
      final container = ProviderContainer(
        overrides: [coreApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(bookshelfNotifierProvider.notifier);
      final firstBook = Book(id: 'first', name: '第一次');
      final secondBook = Book(id: 'second', name: '第二次');

      final firstLoad = notifier.load();
      final secondLoad = notifier.load();
      api.completeAt(1, [secondBook]);
      await secondLoad;
      api.completeAt(0, [firstBook]);
      await firstLoad;

      final state = container.read(bookshelfNotifierProvider);
      expect(state.status, BookshelfStatus.success);
      expect(state.books.single, same(secondBook));
    });

    test('ignores a stale failure after a newer request completes', () async {
      final api = _FakeCoreApi();
      final container = ProviderContainer(
        overrides: [coreApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(bookshelfNotifierProvider.notifier);
      final secondBook = Book(id: 'second', name: '第二次');
      final staleError = StateError('stale request failed');

      final firstLoad = notifier.load();
      final secondLoad = notifier.load();
      api.completeAt(1, [secondBook]);
      await secondLoad;
      api.failAt(0, staleError, StackTrace.current);
      await firstLoad;

      final state = container.read(bookshelfNotifierProvider);
      expect(state.status, BookshelfStatus.success);
      expect(state.books.single, same(secondBook));
      expect(state.error, isNull);
    });

    test('exposes an unmodifiable book list', () async {
      final api = _FakeCoreApi();
      final container = ProviderContainer(
        overrides: [coreApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(bookshelfNotifierProvider.notifier);
      final book = Book(id: 'book-1', name: '示例书');

      final load = notifier.load();
      api.completeNext([book]);
      await load;

      expect(
        () => container.read(bookshelfNotifierProvider).books.add(book),
        throwsUnsupportedError,
      );
    });
  });
}

class _FakeCoreApi implements CoreApi {
  final _pending = <Completer<List<Book>>>[];

  int get getBookshelfCalls => _pending.length;

  @override
  Future<List<Book>> getBookshelf() {
    final completer = Completer<List<Book>>();
    _pending.add(completer);
    return completer.future;
  }

  void completeNext(List<Book> books) => _pending.removeAt(0).complete(books);

  void completeAt(int index, List<Book> books) =>
      _pending[index].complete(books);

  void failNext(Object error, StackTrace stackTrace) {
    _pending.removeAt(0).completeError(error, stackTrace);
  }

  void failAt(int index, Object error, StackTrace stackTrace) {
    _pending[index].completeError(error, stackTrace);
  }

  @override
  Future<List<SearchResultItem>> searchBooks({
    required String sourceUrl,
    required String keyword,
  }) async => const [];
}
