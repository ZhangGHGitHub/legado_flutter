import 'package:shared_preferences/shared_preferences.dart';

import 'package:legado_flutter/application/reader/simulated_reading_prefs_port.dart';
import 'package:legado_flutter/domain/book/book.dart';

export 'package:legado_flutter/application/reader/simulated_reading_prefs_port.dart'
    show SimulatedReadingConfig;

/// 模拟追读：优先 Book/DB；旧 SharedPreferences 作迁移源，保存时仍双写便于兜底
abstract final class SimulatedReadingPrefs {
  static String _k(String bookId, String field) => 'sim_read_${bookId}_$field';

  static Future<bool> hasLocalPrefs(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_k(bookId, 'enabled')) ||
        prefs.containsKey(_k(bookId, 'date')) ||
        prefs.containsKey(_k(bookId, 'start')) ||
        prefs.containsKey(_k(bookId, 'daily'));
  }

  /// Book 是否已持久化过模拟追读（有开始日期或曾开启）
  static bool hasBookData(Book book) =>
      book.simReadStartDate.isNotEmpty || book.simReadEnabled;

  static Future<SimulatedReadingConfig> load(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_k(bookId, 'enabled')) ?? false;
    final dateStr = prefs.getString(_k(bookId, 'date'));
    final startDate = dateStr != null && dateStr.isNotEmpty
        ? DateTime.tryParse(dateStr) ?? DateTime.now()
        : DateTime.now();
    final startChapter = prefs.getInt(_k(bookId, 'start')) ?? 0;
    final daily = prefs.getInt(_k(bookId, 'daily')) ?? 3;
    return SimulatedReadingConfig(
      enabled: enabled,
      startDate: startDate,
      startChapter: startChapter < 0 ? 0 : startChapter,
      dailyChapters: daily < 1 ? 1 : daily,
    );
  }

  /// 优先 Book；无 Book 数据时回退旧 SP，并标记需迁入 Book
  static Future<({SimulatedReadingConfig config, bool needsBookMigrate})>
      loadForBook(Book book) async {
    if (hasBookData(book)) {
      return (
        config: SimulatedReadingConfig.fromBook(book),
        needsBookMigrate: false,
      );
    }
    if (await hasLocalPrefs(book.id)) {
      return (config: await load(book.id), needsBookMigrate: true);
    }
    return (
      config: SimulatedReadingConfig.fromBook(book),
      needsBookMigrate: false,
    );
  }

  static Future<void> save(String bookId, SimulatedReadingConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_k(bookId, 'enabled'), config.enabled);
    await prefs.setString(_k(bookId, 'date'), config.startDateIso);
    await prefs.setInt(_k(bookId, 'start'), config.startChapter);
    await prefs.setInt(_k(bookId, 'daily'), config.dailyChapters);
  }
}
