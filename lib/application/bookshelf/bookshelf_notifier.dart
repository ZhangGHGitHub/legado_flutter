import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/book/book.dart';
import '../core_api_provider.dart';

enum BookshelfStatus { initial, loading, success, failure }

/// Immutable presentation state for the bookshelf feature.
class BookshelfState {
  const BookshelfState._({
    required this.status,
    required this.books,
    this.error,
    this.stackTrace,
    this.isRefreshing = false,
  });

  factory BookshelfState.initial() =>
      const BookshelfState._(status: BookshelfStatus.initial, books: []);

  factory BookshelfState.loading({
    List<Book> books = const [],
    bool isRefreshing = false,
  }) => BookshelfState._(
    status: BookshelfStatus.loading,
    books: List.unmodifiable(books),
    isRefreshing: isRefreshing,
  );

  factory BookshelfState.success(List<Book> books) => BookshelfState._(
    status: BookshelfStatus.success,
    books: List.unmodifiable(books),
  );

  factory BookshelfState.failure(
    Object error,
    StackTrace stackTrace, {
    List<Book> books = const [],
  }) => BookshelfState._(
    status: BookshelfStatus.failure,
    books: List.unmodifiable(books),
    error: error,
    stackTrace: stackTrace,
  );

  final BookshelfStatus status;
  final List<Book> books;
  final Object? error;
  final StackTrace? stackTrace;
  final bool isRefreshing;

  bool get isInitialLoading =>
      status == BookshelfStatus.loading && !isRefreshing;
  bool get isLoading => status == BookshelfStatus.loading;
  bool get hasValue => status == BookshelfStatus.success;
  bool get hasError => status == BookshelfStatus.failure;
}

final bookshelfNotifierProvider =
    NotifierProvider<BookshelfNotifier, BookshelfState>(BookshelfNotifier.new);

class BookshelfNotifier extends Notifier<BookshelfState> {
  var _requestId = 0;

  @override
  BookshelfState build() => BookshelfState.initial();

  Future<void> load() => _fetch(refreshing: false);

  Future<void> refresh() => _fetch(refreshing: true);

  Future<void> _fetch({required bool refreshing}) async {
    final requestId = ++_requestId;
    final previousBooks = state.books;
    state = BookshelfState.loading(
      books: refreshing ? previousBooks : const [],
      isRefreshing: refreshing,
    );

    try {
      final books = await ref.read(coreApiProvider).getBookshelf();
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
