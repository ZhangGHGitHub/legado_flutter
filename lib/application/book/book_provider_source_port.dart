import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';
import '../../domain/ports/reader_content_source_port.dart';
import '../../domain/source/book_source.dart';

/// BookProvider and ReadBook source capabilities.
///
/// The implementation remains responsible for source retry, TOC URL
/// completion, pagination fallback, ordering, and result mapping.
abstract interface class BookProviderSourcePort
    implements ReaderContentSourcePort, PaginatedReaderContentSourcePort {
  Future<Map<String, String>> getBookInfo(BookSource source, String bookUrl);

  Future<List<Map<String, String>>> search(BookSource source, String keyword);

  List<Book> resultsToBooks(
    List<Map<String, String>> results,
    String sourceUrl,
  );

  Future<List<Chapter>> getChapters(Book book, {required BookSource source});
}
