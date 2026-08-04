import 'package:flutter/foundation.dart';

import '../../application/bookshelf/bookshelf_display_state_port.dart';

/// 将现有 BookProvider 的展示状态和重试能力接入书架页面端口。
final class BookshelfDisplayStatePortAdapter
    implements BookshelfDisplayStatePort {
  const BookshelfDisplayStatePortAdapter({
    required Listenable listenable,
    required bool Function() isLoading,
    required bool Function(String bookId) isBookUpdating,
    required Future<void> Function() reload,
  }) : _listenable = listenable,
       _isLoading = isLoading,
       _isBookUpdating = isBookUpdating,
       _reload = reload;

  final Listenable _listenable;
  final bool Function() _isLoading;
  final bool Function(String bookId) _isBookUpdating;
  final Future<void> Function() _reload;

  @override
  bool get isLoading => _isLoading();

  @override
  bool isBookUpdating(String bookId) => _isBookUpdating(bookId);

  @override
  Future<void> reload() => _reload();

  @override
  void addListener(VoidCallback listener) => _listenable.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _listenable.removeListener(listener);
}
