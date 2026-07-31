import '../../domain/book/book.dart';
import '../../domain/reader/book_progress.dart';

typedef BatchBookProgressApply =
    Future<void> Function(Book book, BookProgress progress);

/// Application boundary for downloading and applying bookshelf progress.
abstract interface class BatchBookProgressSyncPort {
  Future<int> downloadAllBookProgress({
    required Iterable<Book> books,
    required BatchBookProgressApply apply,
  });
}
