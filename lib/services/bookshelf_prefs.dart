import 'package:shared_preferences/shared_preferences.dart';

/// 书架布局偏好（对齐 Legado bookGroupStyle / bookshelfSort）
abstract final class BookshelfPrefs {
  static const bookGroupStyleKey = 'bookGroupStyle';
  static const shelfBookOrderKey = 'shelf_book_order';
  static const shelfSortModeKey = 'shelf_sort_mode';

  /// 0 = style1 列表，1 = style2 网格
  static Future<int> loadGroupStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(bookGroupStyleKey) ?? 0;
  }

  static Future<void> saveGroupStyle(int style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(bookGroupStyleKey, style);
  }

  /// 自定义排序书 ID 列表（对齐 legado `order` / bookshelfSort=3）
  static Future<List<String>> loadBookOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(shelfBookOrderKey) ?? [];
  }

  static Future<void> saveBookOrder(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(shelfBookOrderKey, ids);
  }

  /// 0=阅读时间 1=更新时间 2=书名 3=手动排序（对齐 AppConfig.bookshelfSort）
  static Future<int> loadSortMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(shelfSortModeKey) ?? 3;
  }

  static Future<void> saveSortMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(shelfSortModeKey, mode);
  }

  /// 将 [books] 按已保存顺序重排；未知书追加在末尾。
  static List<T> applyBookOrder<T>(List<T> books, List<String> orderIds, String Function(T) idOf) {
    if (orderIds.isEmpty) return books;
    final rank = <String, int>{};
    for (var i = 0; i < orderIds.length; i++) {
      rank[orderIds[i]] = i;
    }
    final sorted = [...books];
    sorted.sort((a, b) {
      final ra = rank[idOf(a)] ?? 1 << 20;
      final rb = rank[idOf(b)] ?? 1 << 20;
      return ra.compareTo(rb);
    });
    return sorted;
  }
}
