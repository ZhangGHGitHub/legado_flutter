import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';

/// 离线缓存页读取书架和本地目录所需的应用端口。
///
/// [books] 每次访问都返回不可变快照，避免页面加载缓存统计期间受到书架
/// 列表原地修改的影响。
abstract interface class CacheBookShelfPort {
  List<Book> get books;

  Future<int> getChapterCount(String bookId);

  Future<List<Chapter>> getLocalChapters(String bookId);
}

/// 未通过组合根注入时，复用现有书架事实源的应用层回调实现。
final class CacheBookShelfPortCallbacks implements CacheBookShelfPort {
  const CacheBookShelfPortCallbacks({
    required List<Book> Function() books,
    required Future<int> Function(String bookId) getChapterCount,
    required Future<List<Chapter>> Function(String bookId) getLocalChapters,
  }) : _books = books,
       _getChapterCount = getChapterCount,
       _getLocalChapters = getLocalChapters;

  final List<Book> Function() _books;
  final Future<int> Function(String bookId) _getChapterCount;
  final Future<List<Chapter>> Function(String bookId) _getLocalChapters;

  @override
  List<Book> get books => List<Book>.unmodifiable(_books());

  @override
  Future<int> getChapterCount(String bookId) => _getChapterCount(bookId);

  @override
  Future<List<Chapter>> getLocalChapters(String bookId) =>
      _getLocalChapters(bookId);
}

/// 独立宿主未提供书架能力时的明确空实现。
final class EmptyCacheBookShelfPort implements CacheBookShelfPort {
  const EmptyCacheBookShelfPort();

  @override
  List<Book> get books => const [];

  @override
  Future<int> getChapterCount(String bookId) async => 0;

  @override
  Future<List<Chapter>> getLocalChapters(String bookId) async => const [];
}
