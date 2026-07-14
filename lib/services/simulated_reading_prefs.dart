import 'package:shared_preferences/shared_preferences.dart';

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

/// 按书持久化模拟追读（Flutter 侧尚未并入 Book JSON）
abstract final class SimulatedReadingPrefs {
  static String _k(String bookId, String field) => 'sim_read_${bookId}_$field';

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
      startChapter: startChapter,
      dailyChapters: daily < 1 ? 1 : daily,
    );
  }

  static Future<void> save(String bookId, SimulatedReadingConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_k(bookId, 'enabled'), config.enabled);
    final d = config.startDate;
    final dateStr =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await prefs.setString(_k(bookId, 'date'), dateStr);
    await prefs.setInt(_k(bookId, 'start'), config.startChapter);
    await prefs.setInt(_k(bookId, 'daily'), config.dailyChapters);
  }
}
