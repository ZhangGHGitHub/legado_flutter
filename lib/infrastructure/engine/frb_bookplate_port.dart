import '../../bridge/legado_engine_bridge.dart';
import '../../domain/book_reading_stats.dart';
import '../../domain/ports/bookplate_port.dart';
import '../../src/rust/api.dart' as rust_api;

class FrbBookplatePort implements BookplatePort {
  @override
  bool get isAvailable => LegadoEngineBridge.isAvailable;

  @override
  BookReadingStats? loadBookStats(String bookId) {
    if (!isAvailable) return null;
    try {
      return _fromGenerated(rust_api.getBookReadingStats(bookId: bookId));
    } catch (_) {
      return null;
    }
  }

  static BookReadingStats _fromGenerated(rust_api.BookReadingStats stats) {
    return BookReadingStats(
      readChars: stats.readChars,
      durationSeconds: stats.durationSeconds,
      startDate: stats.startDate,
      lastDate: stats.lastDate,
      readingDays: stats.readingDays,
    );
  }
}
