import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';

/// 模拟追读配置（对齐 legado Book.ReadConfig + `dialog_simulated_reading`）
class SimulatedReadingConfig {
  final bool enabled;
  final DateTime startDate;
  /// 0-based 起始章节索引（legado `startChapter`）
  final int startChapter;
  final int dailyChapters;

  const SimulatedReadingConfig({
    this.enabled = false,
    required this.startDate,
    this.startChapter = 0,
    this.dailyChapters = 3,
  });

  SimulatedReadingConfig copyWith({
    bool? enabled,
    DateTime? startDate,
    int? startChapter,
    int? dailyChapters,
  }) {
    return SimulatedReadingConfig(
      enabled: enabled ?? this.enabled,
      startDate: startDate ?? this.startDate,
      startChapter: startChapter ?? this.startChapter,
      dailyChapters: dailyChapters ?? this.dailyChapters,
    );
  }

  /// YYYY-MM-DD（写入 Book / DB）
  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String get startDateIso => formatDate(startDate);

  factory SimulatedReadingConfig.fromBook(Book book) {
    final dateStr = book.simReadStartDate;
    final startDate = dateStr.isNotEmpty
        ? (DateTime.tryParse(dateStr) ?? DateTime.now())
        : DateTime.now();
    final daily = book.simReadDailyChapters < 1 ? 3 : book.simReadDailyChapters;
    return SimulatedReadingConfig(
      enabled: book.simReadEnabled,
      startDate: startDate,
      startChapter: book.simReadStartChapter < 0 ? 0 : book.simReadStartChapter,
      dailyChapters: daily.clamp(1, 999),
    );
  }

  /// 对齐 `Book.simulatedTotalChapterNum()`：已解锁章数（1…total）
  int simulatedTotalChapterNum(int totalChapterNum) {
    if (!enabled || totalChapterNum <= 0) return totalChapterNum;
    final now = DateTime.now();
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final today = DateTime(now.year, now.month, now.day);
    final daysPassed = today.difference(start).inDays + 1;
    final chaptersToUnlock =
        (startChapter + (daysPassed * dailyChapters)).clamp(0, 1 << 30);
    if (chaptersToUnlock < totalChapterNum) return chaptersToUnlock;
    return totalChapterNum;
  }

  /// 可读的最大章节索引（含）
  int maxReadableIndex(int totalChapterNum) {
    final n = simulatedTotalChapterNum(totalChapterNum);
    if (n <= 0) return -1;
    return n - 1;
  }
}

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
