/// 书架整理页使用的持久化端口。
///
/// 页面只依赖这些行为，不直接知道 SharedPreferences 或旧版服务实现。
abstract interface class BookshelfArrangePort {
  static const openBookInfoByTitleKey = 'openBookInfoByClickTitle';

  Future<bool> loadOpenBookInfoByTitle();

  Future<void> saveOpenBookInfoByTitle(bool value);

  Future<int> loadSortMode();

  Future<List<String>> loadBookOrder();

  Future<void> saveBookOrder(List<String> ids);

  Future<void> saveSortMode(int mode);
}

/// 书架整理页的纯顺序策略，保持 BookshelfPrefs 的未知书追加语义。
abstract final class BookshelfArrangeOrderPolicy {
  static List<T> apply<T>(
    List<T> books,
    List<String> orderIds,
    String Function(T) idOf,
  ) {
    if (orderIds.isEmpty) return List<T>.of(books);
    final rank = <String, int>{};
    for (var i = 0; i < orderIds.length; i++) {
      rank[orderIds[i]] = i;
    }
    final sorted = [...books];
    sorted.sort((a, b) {
      final rankA = rank[idOf(a)] ?? 1 << 20;
      final rankB = rank[idOf(b)] ?? 1 << 20;
      return rankA.compareTo(rankB);
    });
    return sorted;
  }
}
