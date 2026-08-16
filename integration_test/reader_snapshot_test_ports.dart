import 'package:legado_flutter/application/reader/reader_progress_sync_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/reader/book_progress.dart';

final class NoopReaderProgressSyncPort implements ReaderProgressSyncPort {
  const NoopReaderProgressSyncPort();

  @override
  Future<BookProgress?> getBookProgress(Book book) async => null;

  @override
  Future<bool> isConfigured() async => false;

  @override
  Future<void> uploadBookProgress(
    BookProgress progress, {
    bool toast = false,
  }) async {}
}
