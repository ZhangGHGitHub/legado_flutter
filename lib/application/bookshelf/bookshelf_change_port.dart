import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signals that the persisted bookshelf snapshot has changed.
abstract interface class BookshelfChangePort {
  Stream<int> get changes;

  void notifyChanged();
}

/// In-memory change bus shared by the application composition root.
final class BookshelfChangeBus implements BookshelfChangePort {
  BookshelfChangeBus({bool sync = true})
    : _controller = StreamController<int>.broadcast(sync: sync);

  final StreamController<int> _controller;
  int _revision = 0;

  int get revision => _revision;

  @override
  Stream<int> get changes => _controller.stream;

  @override
  void notifyChanged() {
    if (_controller.isClosed) return;
    _controller.add(++_revision);
  }

  Future<void> dispose() => _controller.close();
}

/// Fallback for isolated Provider/ChangeNotifier consumers without a root bus.
final class NoopBookshelfChangePort implements BookshelfChangePort {
  const NoopBookshelfChangePort();

  @override
  Stream<int> get changes => const Stream<int>.empty();

  @override
  void notifyChanged() {}
}

final bookshelfChangePortProvider = Provider<BookshelfChangePort>((ref) {
  final bus = BookshelfChangeBus();
  ref.onDispose(bus.dispose);
  return bus;
});
