import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/book/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../core_api.dart';
import '../core_api_provider.dart';

/// Application boundary for reading the current bookshelf.
abstract interface class BookshelfPort {
  Future<List<Book>> loadBookshelf();
}

/// Adapts the domain repository to the bookshelf application port.
class RepositoryBookshelfPort implements BookshelfPort {
  const RepositoryBookshelfPort(this.repository);

  final BookRepository repository;

  @override
  Future<List<Book>> loadBookshelf() => repository.getAll();
}

/// Adapts the legacy CoreApi bookshelf read to the application port.
class CoreApiBookshelfPort implements BookshelfPort {
  const CoreApiBookshelfPort(this.coreApi);

  final CoreApi coreApi;

  @override
  Future<List<Book>> loadBookshelf() => coreApi.getBookshelf();
}

/// Application use case for reading the bookshelf.
class BookshelfController {
  const BookshelfController(this._port);

  final BookshelfPort _port;

  Future<List<Book>> loadBookshelf() => _port.loadBookshelf();
}

/// Default migration provider. Production overrides this with the repository
/// adapter at the composition root; isolated tests retain the CoreApi fallback.
final bookshelfControllerProvider = Provider<BookshelfController>(
  (ref) =>
      BookshelfController(CoreApiBookshelfPort(ref.watch(coreApiProvider))),
);
