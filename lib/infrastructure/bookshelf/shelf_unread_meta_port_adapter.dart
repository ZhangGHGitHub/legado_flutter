import 'package:flutter/foundation.dart';

import '../../application/bookshelf/shelf_unread_meta_port.dart';

/// 将现有 BookProvider 的章节元数据快照接入书架未读角标端口。
final class ShelfUnreadMetaPortAdapter implements ShelfUnreadMetaPort {
  const ShelfUnreadMetaPortAdapter({
    required Listenable listenable,
    required ({int count, int? durIndex})? Function(String bookId) metaFor,
  }) : _listenable = listenable,
       _metaFor = metaFor;

  final Listenable _listenable;
  final ({int count, int? durIndex})? Function(String bookId) _metaFor;

  @override
  ({int count, int? durIndex})? metaFor(String bookId) => _metaFor(bookId);

  @override
  void addListener(VoidCallback listener) => _listenable.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _listenable.removeListener(listener);
}
