import 'package:shared_preferences/shared_preferences.dart';

/// 单本书阅读配置（对齐 Jingshiro `Book.config`：pageAnim / reSegment）
class BookReaderPrefs {
  BookReaderPrefs._();

  static String _pageAnimKey(String bookId) => 'book_page_anim:$bookId';
  static String _reSegmentKey(String bookId) => 'book_re_segment:$bookId';

  /// `null` / 未写入 = 跟随全局；`-1` = 显式默认；`0..4` = 覆盖/滑动/仿真/滚动/无
  static Future<int?> getPageAnim(String bookId) async {
    final p = await SharedPreferences.getInstance();
    if (!p.containsKey(_pageAnimKey(bookId))) return null;
    return p.getInt(_pageAnimKey(bookId));
  }

  static Future<void> setPageAnim(String bookId, int pageAnim) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_pageAnimKey(bookId), pageAnim);
  }

  static Future<bool> getReSegment(String bookId) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_reSegmentKey(bookId)) ?? false;
  }

  static Future<void> setReSegment(String bookId, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_reSegmentKey(bookId), value);
  }
}
