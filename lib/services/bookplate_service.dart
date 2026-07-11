import '../bridge/legado_engine_bridge.dart';
import '../models/book.dart';
import '../src/rust/api.dart' as rust_api;
import 'reading_record_service.dart';

/// 阅读小票展示数据（Phase 4.4）
class BookplateData {
  final String bookName;
  final String author;
  final double rating;
  final String durationLabel;
  final String charsLabel;
  final String? startDate;
  final String? finishDate;
  final int chaptersRead;
  final int totalChapters;
  final double progress;

  const BookplateData({
    required this.bookName,
    required this.author,
    required this.rating,
    required this.durationLabel,
    required this.charsLabel,
    this.startDate,
    this.finishDate,
    required this.chaptersRead,
    required this.totalChapters,
    required this.progress,
  });
}

/// 阅读小票数据组装
abstract final class BookplateService {
  static rust_api.BookReadingStats? loadBookStats(String bookId) {
    if (!LegadoEngineBridge.isAvailable) return null;
    try {
      return rust_api.getBookReadingStats(bookId: bookId);
    } catch (_) {
      return null;
    }
  }

  static BookplateData build({
    required Book book,
    required int currentChapterIndex,
    required int totalChapters,
    rust_api.BookReadingStats? stats,
  }) {
    final safeTotal = totalChapters <= 0 ? 1 : totalChapters;
    final chaptersRead = (currentChapterIndex + 1).clamp(1, safeTotal);
    final progress = book.progress.clamp(0.0, 1.0);
    final completed = progress >= 0.999 || chaptersRead >= safeTotal;

    final durationSeconds = stats?.durationSeconds ?? 0;
    final readChars = stats?.readChars ?? 0;

    return BookplateData(
      bookName: book.name,
      author: book.author,
      rating: ratingFromProgress(progress),
      durationLabel: ReadingRecordService.formatDuration(durationSeconds),
      charsLabel: ReadingRecordService.formatChars(readChars),
      startDate: stats?.startDate,
      finishDate: completed ? stats?.lastDate : null,
      chaptersRead: chaptersRead,
      totalChapters: safeTotal,
      progress: progress,
    );
  }

  static double ratingFromProgress(double progress) {
    return (progress * 5).clamp(0.0, 5.0);
  }

  static String formatDateLabel(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '—';
    return isoDate;
  }
}
