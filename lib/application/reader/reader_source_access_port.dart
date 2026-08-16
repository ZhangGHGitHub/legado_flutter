import '../../domain/book/book.dart';
import '../../domain/source/book_source.dart';

/// 普通阅读器读取书源和执行自动换源所需的 application 边界。
abstract interface class ReaderSourceAccessPort {
  BookSource? sourceForBook(Book book);

  List<BookSource> get availableSources;

  Future<Book?> autoChangeSource(
    Book book, {
    required List<BookSource> sources,
    int concurrency = 4,
  });
}

typedef ReaderBookSourceFinder = BookSource? Function(Book book);
typedef ReaderAvailableSources = List<BookSource> Function();
typedef ReaderAutoSourceChanger =
    Future<Book?> Function(
      Book book, {
      required List<BookSource> sources,
      int concurrency,
    });

/// 独立宿主未提供书源能力时的回调实现。
final class ReaderSourceAccessPortCallbacks implements ReaderSourceAccessPort {
  const ReaderSourceAccessPortCallbacks({
    required ReaderBookSourceFinder sourceForBook,
    required ReaderAvailableSources availableSources,
    required ReaderAutoSourceChanger autoChangeSource,
  }) : _sourceForBook = sourceForBook,
       _availableSources = availableSources,
       _autoChangeSource = autoChangeSource;

  final ReaderBookSourceFinder _sourceForBook;
  final ReaderAvailableSources _availableSources;
  final ReaderAutoSourceChanger _autoChangeSource;

  @override
  BookSource? sourceForBook(Book book) => _sourceForBook(book);

  @override
  List<BookSource> get availableSources =>
      List<BookSource>.unmodifiable(_availableSources());

  @override
  Future<Book?> autoChangeSource(
    Book book, {
    required List<BookSource> sources,
    int concurrency = 4,
  }) => _autoChangeSource(book, sources: sources, concurrency: concurrency);
}

/// 独立宿主未提供书源能力时的明确空实现。
final class EmptyReaderSourceAccessPort implements ReaderSourceAccessPort {
  const EmptyReaderSourceAccessPort();

  @override
  BookSource? sourceForBook(Book book) => null;

  @override
  List<BookSource> get availableSources => const [];

  @override
  Future<Book?> autoChangeSource(
    Book book, {
    required List<BookSource> sources,
    int concurrency = 4,
  }) async => null;
}
