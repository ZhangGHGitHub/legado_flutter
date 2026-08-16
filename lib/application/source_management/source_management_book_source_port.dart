import '../../domain/book/book.dart';
import '../../domain/source/book_source.dart';

/// Source import and search capabilities used by source management flows.
abstract interface class SourceManagementBookSourcePort {
  Future<List<BookSource>> fetchSourcesFromUrl(String url);

  Future<List<Map<String, String>>> search(BookSource source, String keyword);

  List<Book> resultsToBooks(
    List<Map<String, String>> results,
    String sourceUrl,
  );
}
