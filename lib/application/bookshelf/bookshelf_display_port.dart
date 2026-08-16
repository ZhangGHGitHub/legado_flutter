import '../../domain/book/book.dart';
import '../../services/bookshelf_prefs.dart' show BookshelfConfig;

export '../../services/bookshelf_prefs.dart' show BookshelfConfig;

/// 书架展示所需的配置、手动顺序和排序行为端口。
///
/// 展示页面不直接知道 SharedPreferences 或旧版 BookshelfPrefs 的实现。
abstract interface class BookshelfDisplayPort {
  Future<BookshelfConfig> loadConfig();

  Future<List<String>> loadBookOrder();

  List<Book> sortBooks(
    List<Book> books, {
    required int sortMode,
    required List<String> orderIds,
    Set<String> pinnedIds,
  });
}

/// 没有组合根注入时供独立测试宿主使用的内存实现。
final class InMemoryBookshelfDisplayPort implements BookshelfDisplayPort {
  const InMemoryBookshelfDisplayPort();

  @override
  Future<BookshelfConfig> loadConfig() async => const BookshelfConfig();

  @override
  Future<List<String>> loadBookOrder() async => const [];

  @override
  List<Book> sortBooks(
    List<Book> books, {
    required int sortMode,
    required List<String> orderIds,
    Set<String> pinnedIds = const {},
  }) => [...books];
}
