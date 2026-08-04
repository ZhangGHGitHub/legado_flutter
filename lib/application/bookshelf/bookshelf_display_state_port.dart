import 'package:flutter/foundation.dart';

/// 书架页面所需的加载、重试和单本目录更新展示状态。
abstract interface class BookshelfDisplayStatePort extends Listenable {
  bool get isLoading;

  bool isBookUpdating(String bookId);

  Future<void> reload();
}

/// 独立宿主未提供 Provider 展示状态时的空实现。
final class EmptyBookshelfDisplayStatePort
    implements BookshelfDisplayStatePort {
  const EmptyBookshelfDisplayStatePort();

  @override
  bool get isLoading => false;

  @override
  bool isBookUpdating(String bookId) => false;

  @override
  Future<void> reload() async {}

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
