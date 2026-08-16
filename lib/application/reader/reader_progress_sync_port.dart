import '../../domain/book/book.dart';
import '../../domain/reader/book_progress.dart';

/// Application boundary for ReaderPage cloud progress operations.
abstract interface class ReaderProgressSyncPort {
  Future<bool> isConfigured();

  Future<BookProgress?> getBookProgress(Book book);

  Future<void> uploadBookProgress(BookProgress progress, {bool toast = false});
}
