import '../../domain/book/book.dart';
import '../../domain/source/book_source.dart';

/// 换源并刷新目录所需的 application 写入端口。
abstract interface class BookSourceChangePort {
  Future<Book> changeSource(
    Book current,
    Book selected, {
    required BookSource source,
  });

  Future<void> loadChapters(
    Book book, {
    required BookSource source,
    bool forceRefresh = false,
  });
}

/// 独立宿主未提供换源能力时的明确空实现。
final class EmptyBookSourceChangePort implements BookSourceChangePort {
  const EmptyBookSourceChangePort();

  @override
  Future<Book> changeSource(
    Book current,
    Book selected, {
    required BookSource source,
  }) => Future<Book>.error(UnsupportedError('换源服务不可用'));

  @override
  Future<void> loadChapters(
    Book book, {
    required BookSource source,
    bool forceRefresh = false,
  }) => Future<void>.error(UnsupportedError('目录服务不可用'));
}
