import '../../application/reader/reader_chapter_refresh_port.dart';
import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';
import '../../domain/source/book_source.dart';

/// 将现有 BookProvider 的强制目录刷新接入 application 端口。
final class ReaderChapterRefreshPortAdapter
    implements ReaderChapterRefreshPort {
  const ReaderChapterRefreshPortAdapter({
    required Future<void> Function(
      Book book, {
      required BookSource source,
      required bool forceRefresh,
    })
    loadChapters,
    required List<Chapter> Function() currentChapters,
  }) : _loadChapters = loadChapters,
       _currentChapters = currentChapters;

  final Future<void> Function(
    Book book, {
    required BookSource source,
    required bool forceRefresh,
  })
  _loadChapters;
  final List<Chapter> Function() _currentChapters;

  @override
  Future<List<Chapter>> refreshChapters(
    Book book, {
    required BookSource source,
  }) async {
    await _loadChapters(book, source: source, forceRefresh: true);
    return List<Chapter>.unmodifiable(_currentChapters());
  }
}
