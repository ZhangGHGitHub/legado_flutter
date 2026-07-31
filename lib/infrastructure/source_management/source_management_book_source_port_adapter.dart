import '../../application/source_management/source_management_book_source_port.dart';
import '../../domain/book/book.dart';
import '../../domain/source/book_source.dart';
import '../../services/book_source_service.dart';

/// Delegates source-management import and search work to the existing facade.
final class SourceManagementBookSourcePortAdapter
    implements SourceManagementBookSourcePort {
  const SourceManagementBookSourcePortAdapter({
    required BookSourceService sourceService,
  }) : _sourceService = sourceService;

  final BookSourceService _sourceService;

  @override
  Future<List<BookSource>> fetchSourcesFromUrl(String url) =>
      _sourceService.fetchSourcesFromUrl(url);

  @override
  Future<List<Map<String, String>>> search(BookSource source, String keyword) =>
      _sourceService.search(source, keyword);

  @override
  List<Book> resultsToBooks(
    List<Map<String, String>> results,
    String sourceUrl,
  ) => _sourceService.resultsToBooks(results, sourceUrl);
}
