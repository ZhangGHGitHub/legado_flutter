import 'package:flutter/foundation.dart';

import '../../application/bookshelf/bookshelf_membership_port.dart';
import '../../domain/book/book.dart';

/// 将现有 BookProvider 书架快照接入发现页成员查询端口。
final class BookshelfMembershipPortAdapter implements BookshelfMembershipPort {
  const BookshelfMembershipPortAdapter({
    required Listenable listenable,
    required List<Book> Function() books,
  }) : _listenable = listenable,
       _books = books;

  final Listenable _listenable;
  final List<Book> Function() _books;

  @override
  List<Book> get books => List<Book>.unmodifiable(_books());

  @override
  void addListener(VoidCallback listener) => _listenable.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _listenable.removeListener(listener);
}
