import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/book/book.dart';

/// Signals that the persisted bookshelf snapshot has changed.
abstract interface class BookshelfChangePort {
  Stream<BookshelfChange> get changes;

  BookshelfChange? get latest;

  void notifyChanged(List<Book> books);
}

final class BookshelfChange {
  BookshelfChange({required this.revision, required List<Book> books})
    : books = List.unmodifiable(books);

  final int revision;
  final List<Book> books;
}

/// In-memory change bus shared by the application composition root.
final class BookshelfChangeBus implements BookshelfChangePort {
  BookshelfChangeBus({bool sync = true})
    : _controller = StreamController<BookshelfChange>.broadcast(sync: sync);

  final StreamController<BookshelfChange> _controller;
  int _revision = 0;
  BookshelfChange? _latest;

  int get revision => _revision;

  @override
  Stream<BookshelfChange> get changes => _controller.stream;

  @override
  BookshelfChange? get latest => _latest;

  @override
  void notifyChanged(List<Book> books) {
    if (_controller.isClosed) return;
    final change = BookshelfChange(revision: ++_revision, books: books);
    _latest = change;
    _controller.add(change);
  }

  Future<void> dispose() => _controller.close();
}

/// Fallback for isolated Provider/ChangeNotifier consumers without a root bus.
final class NoopBookshelfChangePort implements BookshelfChangePort {
  const NoopBookshelfChangePort();

  @override
  Stream<BookshelfChange> get changes => const Stream<BookshelfChange>.empty();

  @override
  BookshelfChange? get latest => null;

  @override
  void notifyChanged(List<Book> books) {}
}

final bookshelfChangePortProvider = Provider<BookshelfChangePort>((ref) {
  final bus = BookshelfChangeBus();
  ref.onDispose(bus.dispose);
  return bus;
});
