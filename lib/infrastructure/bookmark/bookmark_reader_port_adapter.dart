import '../../application/bookmark/bookmark_reader_port.dart';
import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';
import '../../domain/source/book_source.dart';

/// 以回调形式复用现有 BookProvider 的书签阅读跳转行为。
final class BookmarkReaderPortAdapter implements BookmarkReaderPort {
  const BookmarkReaderPortAdapter({
    required Book? Function(String bookId) findBookById,
    required List<Chapter> Function() currentChapters,
    required Future<void> Function(Book book, {required BookSource source})
    loadChapters,
    required Future<List<Chapter>> Function(String bookId) getLocalChapters,
  }) : _findBookById = findBookById,
       _currentChapters = currentChapters,
       _loadChapters = loadChapters,
       _getLocalChapters = getLocalChapters;

  final Book? Function(String bookId) _findBookById;
  final List<Chapter> Function() _currentChapters;
  final Future<void> Function(Book book, {required BookSource source})
  _loadChapters;
  final Future<List<Chapter>> Function(String bookId) _getLocalChapters;

  @override
  Book? findBookById(String bookId) => _findBookById(bookId);

  @override
  List<Chapter> get currentChapters =>
      List<Chapter>.unmodifiable(_currentChapters());

  @override
  Future<void> loadChapters(Book book, {required BookSource source}) =>
      _loadChapters(book, source: source);

  @override
  Future<List<Chapter>> getLocalChapters(String bookId) async =>
      List<Chapter>.unmodifiable(await _getLocalChapters(bookId));
}
