import '../../application/reader/reader_source_access_port.dart';
import '../../domain/book/book.dart';
import '../../domain/source/book_source.dart';

/// 将现有 SourceProvider 的书源访问和 BookProvider 的自动换源接入端口。
final class ReaderSourceAccessPortAdapter implements ReaderSourceAccessPort {
  const ReaderSourceAccessPortAdapter({
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
