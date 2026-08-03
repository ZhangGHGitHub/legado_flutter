import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/book/book.dart';
import 'bookshelf_change_port.dart';
import 'bookshelf_controller.dart';

part 'bookshelf_notifier.freezed.dart';

enum BookshelfStatus { initial, loading, success, failure }

/// Immutable presentation state for the bookshelf feature.
@freezed
class BookshelfState with _$BookshelfState {
  const BookshelfState._();

  const factory BookshelfState._value({
    required BookshelfStatus status,
    @Default(<Book>[]) List<Book> books,
    Object? error,
    StackTrace? stackTrace,
    @Default(false) bool isRefreshing,
  }) = _BookshelfState;

  factory BookshelfState.initial() =>
      const BookshelfState._value(status: BookshelfStatus.initial);

  factory BookshelfState.loading({
    List<Book> books = const [],
    bool isRefreshing = false,
  }) => BookshelfState._value(
    status: BookshelfStatus.loading,
    books: List.unmodifiable(books),
    isRefreshing: isRefreshing,
  );

  factory BookshelfState.success(List<Book> books) => BookshelfState._value(
    status: BookshelfStatus.success,
    books: List.unmodifiable(books),
  );

  factory BookshelfState.failure(
    Object error,
    StackTrace stackTrace, {
    List<Book> books = const [],
  }) => BookshelfState._value(
    status: BookshelfStatus.failure,
    books: List.unmodifiable(books),
    error: error,
    stackTrace: stackTrace,
  );

  bool get isInitialLoading =>
      status == BookshelfStatus.loading && !isRefreshing;
  bool get isLoading => status == BookshelfStatus.loading;
  bool get hasValue => status == BookshelfStatus.success;
  bool get hasError => status == BookshelfStatus.failure;
}

final bookshelfNotifierProvider =
    NotifierProvider<BookshelfNotifier, BookshelfState>(
      BookshelfNotifier.new,
      dependencies: [bookshelfControllerProvider],
    );

class BookshelfNotifier extends Notifier<BookshelfState> {
  var _requestId = 0;
  late BookshelfController _controller;
  late BookshelfChangePort _changePort;

  @override
  BookshelfState build() {
    _controller = ref.watch(bookshelfControllerProvider);
    _changePort = ref.watch(bookshelfChangePortProvider);
    final subscription = _changePort.changes.listen((change) {
      _publishSnapshot(change.books);
    });
    ref.onDispose(subscription.cancel);
    final latest = _changePort.latest;
    return latest == null
        ? BookshelfState.initial()
        : BookshelfState.success(latest.books);
  }

  Future<void> load() => _fetch(refreshing: false);

  Future<void> refresh() => _fetch(refreshing: true);

  void _publishSnapshot(List<Book> books) {
    _requestId++;
    state = BookshelfState.success(books);
  }

  Future<void> _fetch({required bool refreshing}) async {
    final requestId = ++_requestId;
    final previousBooks = state.books;
    state = BookshelfState.loading(
      books: refreshing ? previousBooks : const [],
      isRefreshing: refreshing,
    );

    try {
      final books = await _controller.loadBookshelf();
      if (requestId != _requestId) {
        return;
      }
      state = BookshelfState.success(books);
    } catch (error, stackTrace) {
      if (requestId != _requestId) {
        return;
      }
      state = BookshelfState.failure(
        error,
        stackTrace,
        books: refreshing ? previousBooks : const [],
      );
    }
  }
}
