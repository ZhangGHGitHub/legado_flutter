import '../domain/book/book.dart';
import '../domain/search_result_item.dart';

enum CoreApiErrorKind {
  network,
  parse,
  database,
  jsExecution,
  validation,
  unsupported,
  cancelled,
  unknown,
}

class CoreApiException implements Exception {
  const CoreApiException(this.kind, this.message, {this.cause});

  final CoreApiErrorKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => 'CoreApiException($kind): $message';
}

/// Stable application contract shared by MockCoreApi and RealCoreApi.
abstract interface class CoreApi {
  Future<List<Book>> getBookshelf();

  Future<List<SearchResultItem>> searchBooks({
    required String sourceUrl,
    required String keyword,
  });
}
