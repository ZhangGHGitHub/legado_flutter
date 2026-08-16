import '../domain/book/book.dart';
import '../domain/repositories/book_repository.dart';
import '../domain/repositories/book_source_repository.dart';
import '../domain/search_result_item.dart';
import 'book/book_provider_source_port.dart';
import 'core_api.dart';

/// Adapter that translates the current ports into the stable CoreApi contract.
class RealCoreApi implements CoreApi {
  const RealCoreApi({
    required BookRepository books,
    required BookSourceRepository sources,
    required BookProviderSourcePort sourceApi,
  }) : _books = books,
       _sources = sources,
       _sourceApi = sourceApi;

  final BookRepository _books;
  final BookSourceRepository _sources;
  final BookProviderSourcePort _sourceApi;

  @override
  Future<List<Book>> getBookshelf() async {
    try {
      return List.unmodifiable(await _books.getAll());
    } catch (error) {
      throw CoreApiException(CoreApiErrorKind.database, '读取书架失败', cause: error);
    }
  }

  @override
  Future<List<SearchResultItem>> searchBooks({
    required String sourceUrl,
    required String keyword,
  }) async {
    final normalizedUrl = sourceUrl.trim();
    if (normalizedUrl.isEmpty || keyword.trim().isEmpty) {
      throw const CoreApiException(CoreApiErrorKind.validation, '书源地址和关键词不能为空');
    }

    try {
      final source = (await _sources.getAll()).where(
        (item) => item.bookSourceUrl == normalizedUrl,
      );
      if (source.isEmpty) {
        throw const CoreApiException(CoreApiErrorKind.validation, '未找到指定书源');
      }
      final results = await _sourceApi.search(source.first, keyword.trim());
      return List.unmodifiable(results.map(SearchResultItem.fromMap));
    } on CoreApiException {
      rethrow;
    } catch (error) {
      throw CoreApiException(CoreApiErrorKind.unknown, '搜索失败', cause: error);
    }
  }
}
