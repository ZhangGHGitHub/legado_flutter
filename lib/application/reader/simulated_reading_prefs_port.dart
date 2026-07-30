import '../../domain/book/book.dart';

/// 模拟追读配置的应用层模型。
final class SimulatedReadingConfig {
  final bool enabled;
  final DateTime startDate;

  /// 0-based 起始章节索引（legado `startChapter`）。
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

  /// YYYY-MM-DD（写入 Book / DB）。
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

  /// 对齐 `Book.simulatedTotalChapterNum()`：已解锁章数（1…total）。
  int simulatedTotalChapterNum(int totalChapterNum) {
    if (!enabled || totalChapterNum <= 0) return totalChapterNum;
    final now = DateTime.now();
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final today = DateTime(now.year, now.month, now.day);
    final daysPassed = today.difference(start).inDays + 1;
    final chaptersToUnlock = (startChapter + (daysPassed * dailyChapters))
        .clamp(0, 1 << 30);
    if (chaptersToUnlock < totalChapterNum) return chaptersToUnlock;
    return totalChapterNum;
  }

  /// 可读的最大章节索引（含）。
  int maxReadableIndex(int totalChapterNum) {
    final n = simulatedTotalChapterNum(totalChapterNum);
    if (n <= 0) return -1;
    return n - 1;
  }
}

/// 模拟追读的应用层持久化边界。
abstract interface class SimulatedReadingPrefsPort {
  Future<({SimulatedReadingConfig config, bool needsBookMigrate})> loadForBook(
    Book book,
  );

  Future<void> save(String bookId, SimulatedReadingConfig config);
}
