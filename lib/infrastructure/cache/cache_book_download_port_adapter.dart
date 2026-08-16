import 'package:flutter/foundation.dart';

import '../../application/cache/cache_book_download_port.dart';
import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';
import '../../domain/source/book_source.dart';

/// 以回调形式复用现有下载状态和命令链路的缓存页适配器。
final class CacheBookDownloadPortAdapter implements CacheBookDownloadPort {
  const CacheBookDownloadPortAdapter({
    required Listenable changes,
    required CacheBookDownloadState Function() state,
    required CacheBookChaptersLoader loadChapters,
    required CacheBookChaptersDownloader downloadAllChapters,
    required VoidCallback cancelDownload,
  }) : _changes = changes,
       _state = state,
       _loadChapters = loadChapters,
       _downloadAllChapters = downloadAllChapters,
       _cancelDownload = cancelDownload;

  final Listenable _changes;
  final CacheBookDownloadState Function() _state;
  final CacheBookChaptersLoader _loadChapters;
  final CacheBookChaptersDownloader _downloadAllChapters;
  final VoidCallback _cancelDownload;

  @override
  CacheBookDownloadState get state => _state();

  @override
  Future<List<Chapter>> loadChapters(
    Book book, {
    required BookSource source,
  }) async =>
      List<Chapter>.unmodifiable(await _loadChapters(book, source: source));

  @override
  Future<void> downloadAllChapters(
    String bookId,
    List<Chapter> chapters,
    BookSource source, {
    int concurrency = 1,
  }) =>
      _downloadAllChapters(bookId, chapters, source, concurrency: concurrency);

  @override
  void cancelDownload() => _cancelDownload();

  @override
  void addListener(VoidCallback listener) => _changes.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _changes.removeListener(listener);
}
