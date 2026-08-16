import 'package:flutter/foundation.dart';

import '../../domain/book/book.dart';

/// 只读查询书架成员并监听书架变化的应用端口。
abstract interface class BookshelfMembershipPort extends Listenable {
  List<Book> get books;
}

/// 独立发现页面宿主未提供书架成员时的空实现。
final class EmptyBookshelfMembershipPort implements BookshelfMembershipPort {
  const EmptyBookshelfMembershipPort();

  @override
  List<Book> get books => const [];

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
