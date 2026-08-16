import '../../application/reader/reader_progress_sync_port.dart';
import '../../domain/book/book.dart';
import '../../domain/reader/book_progress.dart';
import '../../services/book_progress_sync.dart';

/// Exposes the existing BookProgressSync behavior through the reader port.
final class ReaderProgressSyncPortAdapter implements ReaderProgressSyncPort {
  const ReaderProgressSyncPortAdapter({required BookProgressSync progressSync})
    : _progressSync = progressSync;

  final BookProgressSync _progressSync;

  @override
  Future<bool> isConfigured() => _progressSync.isConfigured();

  @override
  Future<BookProgress?> getBookProgress(Book book) =>
      _progressSync.getBookProgress(book);

  @override
  Future<void> uploadBookProgress(
    BookProgress progress, {
    bool toast = false,
  }) => _progressSync.uploadBookProgress(progress, toast: toast);
}
