import '../../application/book/book_source_change_port.dart';
import '../../domain/book/book.dart';
import '../../domain/source/book_source.dart';

/// 以回调形式复用现有 BookProvider 的换源行为。
final class BookSourceChangePortAdapter implements BookSourceChangePort {
  const BookSourceChangePortAdapter({
    required Future<Book> Function(
      Book current,
      Book selected, {
      BookSource? source,
    })
    changeSource,
    required Future<void> Function(
      Book book, {
      required BookSource source,
      bool forceRefresh,
    })
    loadChapters,
  }) : _changeSource = changeSource,
       _loadChapters = loadChapters;

  final Future<Book> Function(Book current, Book selected, {BookSource? source})
  _changeSource;
  final Future<void> Function(
    Book book, {
    required BookSource source,
    bool forceRefresh,
  })
  _loadChapters;

  @override
  Future<Book> changeSource(
    Book current,
    Book selected, {
    required BookSource source,
  }) => _changeSource(current, selected, source: source);

  @override
  Future<void> loadChapters(
    Book book, {
    required BookSource source,
    bool forceRefresh = false,
  }) => _loadChapters(book, source: source, forceRefresh: forceRefresh);
}
