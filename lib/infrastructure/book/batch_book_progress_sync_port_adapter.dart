import '../../application/book/batch_book_progress_sync_port.dart';
import '../../domain/book/book.dart';
import '../../services/book_progress_sync.dart';

/// Exposes the existing batch WebDAV progress behavior through an app port.
final class BatchBookProgressSyncPortAdapter
    implements BatchBookProgressSyncPort {
  const BatchBookProgressSyncPortAdapter({
    required BookProgressSync progressSync,
  }) : _progressSync = progressSync;

  final BookProgressSync _progressSync;

  @override
  Future<int> downloadAllBookProgress({
    required Iterable<Book> books,
    required BatchBookProgressApply apply,
  }) => _progressSync.downloadAllBookProgress(books: books, apply: apply);
}
