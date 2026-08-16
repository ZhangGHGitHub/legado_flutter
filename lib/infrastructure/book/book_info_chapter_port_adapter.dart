import '../../application/book/book_info_chapter_port.dart';
import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';
import '../../domain/source/book_source.dart';

/// 以回调形式复用现有 BookProvider 的缓存优先目录行为。
final class BookInfoChapterPortAdapter implements BookInfoChapterPort {
  const BookInfoChapterPortAdapter({
    required List<Chapter> Function() currentChapters,
    required bool Function() isLoading,
    required bool Function() isRefreshingToc,
    required Future<void> Function(
      Book book, {
      required BookSource source,
      bool forceRefresh,
    })
    loadChapters,
  }) : _currentChapters = currentChapters,
       _isLoading = isLoading,
       _isRefreshingToc = isRefreshingToc,
       _loadChapters = loadChapters;

  final List<Chapter> Function() _currentChapters;
  final bool Function() _isLoading;
  final bool Function() _isRefreshingToc;
  final Future<void> Function(
    Book book, {
    required BookSource source,
    bool forceRefresh,
  })
  _loadChapters;

  @override
  List<Chapter> get currentChapters => _currentChapters();

  @override
  bool get isLoading => _isLoading();

  @override
  bool get isRefreshingToc => _isRefreshingToc();

  @override
  Future<void> loadChapters(
    Book book, {
    required BookSource source,
    bool forceRefresh = false,
  }) => _loadChapters(book, source: source, forceRefresh: forceRefresh);
}
