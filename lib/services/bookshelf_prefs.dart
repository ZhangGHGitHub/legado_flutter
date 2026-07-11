import 'package:shared_preferences/shared_preferences.dart';

/// 书架布局偏好（对齐 Legado bookGroupStyle）
abstract final class BookshelfPrefs {
  static const bookGroupStyleKey = 'bookGroupStyle';

  /// 0 = style1 列表，1 = style2 网格
  static Future<int> loadGroupStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(bookGroupStyleKey) ?? 0;
  }

  static Future<void> saveGroupStyle(int style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(bookGroupStyleKey, style);
  }
}
