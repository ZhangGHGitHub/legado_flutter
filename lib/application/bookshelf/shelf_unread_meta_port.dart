import 'package:flutter/foundation.dart';

/// 书架未读角标所需的章节元数据只读查询边界。
abstract interface class ShelfUnreadMetaPort extends Listenable {
  ({int count, int? durIndex})? metaFor(String bookId);
}

/// 独立宿主未提供书架章节元数据时的空实现。
final class EmptyShelfUnreadMetaPort implements ShelfUnreadMetaPort {
  const EmptyShelfUnreadMetaPort();

  @override
  ({int count, int? durIndex})? metaFor(String bookId) => null;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
