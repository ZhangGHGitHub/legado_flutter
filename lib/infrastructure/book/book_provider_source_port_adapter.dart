import '../../application/book/book_provider_source_port.dart';
import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';
import '../../domain/source/book_source.dart';
import '../../services/book_source_service.dart';

/// Adapter that preserves the existing BookSourceService behavior.
final class BookProviderSourcePortAdapter implements BookProviderSourcePort {
  const BookProviderSourcePortAdapter({
    required BookSourceService sourceService,
  }) : _sourceService = sourceService;

  final BookSourceService _sourceService;

  @override
  Future<Map<String, String>> getBookInfo(BookSource source, String bookUrl) =>
      _sourceService.getBookInfo(source, bookUrl);

  @override
  Future<List<Map<String, String>>> search(BookSource source, String keyword) =>
      _sourceService.search(source, keyword);

  @override
  List<Book> resultsToBooks(
    List<Map<String, String>> results,
    String sourceUrl,
  ) => _sourceService.resultsToBooks(results, sourceUrl);

  @override
  Future<List<Chapter>> getChapters(Book book, {required BookSource source}) =>
      _sourceService.getChapters(book, source: source);

  @override
  Future<String> getChapterContent(String url, {required BookSource source}) =>
      _sourceService.getChapterContent(url, source: source);

  @override
  Future<String> getChapterContentWithNextChapter(
    String url, {
    required BookSource source,
    String? nextChapterUrl,
  }) => _sourceService.getChapterContentWithNextChapter(
    url,
    source: source,
    nextChapterUrl: nextChapterUrl,
  );
}
