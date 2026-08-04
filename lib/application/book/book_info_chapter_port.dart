import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';
import '../../domain/source/book_source.dart';

/// 书籍详情页读取和加载目录所需的应用端口。
abstract interface class BookInfoChapterPort {
  List<Chapter> get currentChapters;

  bool get isLoading;

  bool get isRefreshingToc;

  Future<void> loadChapters(
    Book book, {
    required BookSource source,
    bool forceRefresh,
  });
}

/// 详情页未通过组合根注入端口时使用的回调实现。
///
/// 回调只负责连接既有事实源，目录缓存优先和加载策略仍由宿主服务决定。
class BookInfoChapterPortCallbacks implements BookInfoChapterPort {
  const BookInfoChapterPortCallbacks({
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

/// 独立宿主未提供目录能力时的明确空实现。
final class EmptyBookInfoChapterPort implements BookInfoChapterPort {
  const EmptyBookInfoChapterPort();

  @override
  List<Chapter> get currentChapters => const [];

  @override
  bool get isLoading => false;

  @override
  bool get isRefreshingToc => false;

  @override
  Future<void> loadChapters(
    Book book, {
    required BookSource source,
    bool forceRefresh = false,
  }) => Future<void>.error(UnsupportedError('目录服务不可用'));
}
