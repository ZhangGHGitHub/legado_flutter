import 'package:flutter/foundation.dart';

import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';
import '../../domain/source/book_source.dart';

/// 离线缓存页显示下载进度所需的不可变状态快照。
final class CacheBookDownloadState {
  const CacheBookDownloadState({
    this.isDownloading = false,
    this.downloadBookId = '',
    this.completed = 0,
    this.total = 0,
  });

  final bool isDownloading;
  final String downloadBookId;
  final int completed;
  final int total;

  double get progress => total > 0 ? completed / total : 0.0;
}

typedef CacheBookChaptersLoader =
    Future<List<Chapter>> Function(Book book, {required BookSource source});

typedef CacheBookChaptersDownloader =
    Future<void> Function(
      String bookId,
      List<Chapter> chapters,
      BookSource source, {
      int concurrency,
    });

/// 离线缓存页加载目录、下载章节和取消下载所需的应用端口。
///
/// [loadChapters] 返回不可变目录快照，避免下载选项弹窗期间受到 Provider
/// 当前目录原地替换的影响。
abstract interface class CacheBookDownloadPort implements Listenable {
  CacheBookDownloadState get state;

  Future<List<Chapter>> loadChapters(Book book, {required BookSource source});

  Future<void> downloadAllChapters(
    String bookId,
    List<Chapter> chapters,
    BookSource source, {
    int concurrency = 1,
  });

  void cancelDownload();
}

/// 未通过组合根注入时，复用现有下载事实源的应用层回调实现。
final class CacheBookDownloadPortCallbacks implements CacheBookDownloadPort {
  const CacheBookDownloadPortCallbacks({
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

/// 独立宿主未提供缓存下载能力时的明确空实现。
final class EmptyCacheBookDownloadPort implements CacheBookDownloadPort {
  const EmptyCacheBookDownloadPort();

  @override
  CacheBookDownloadState get state => const CacheBookDownloadState();

  @override
  Future<List<Chapter>> loadChapters(Book book, {required BookSource source}) =>
      Future<List<Chapter>>.error(UnsupportedError('缓存目录服务不可用'));

  @override
  Future<void> downloadAllChapters(
    String bookId,
    List<Chapter> chapters,
    BookSource source, {
    int concurrency = 1,
  }) => Future<void>.error(UnsupportedError('章节缓存服务不可用'));

  @override
  void cancelDownload() {}

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
