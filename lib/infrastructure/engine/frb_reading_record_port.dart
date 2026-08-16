import '../../bridge/legado_db_bridge.dart';
import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/reading_record_port.dart';
import '../../domain/reading_stats.dart';
import '../../src/rust/api.dart' as rust_api;

/// Rust/FRB adapter for reading-record persistence.
class FrbReadingRecordPort implements ReadingRecordPort {
  @override
  bool get isAvailable =>
      LegadoEngineBridge.isAvailable && LegadoDbBridge.isReady;

  @override
  bool recordReading({
    required String bookId,
    required String bookName,
    required int chars,
    required int durationSeconds,
  }) {
    if (!isAvailable) return false;
    try {
      rust_api.recordReading(
        bookId: bookId,
        bookName: bookName,
        chars: chars,
        durationSeconds: durationSeconds,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  bool recordDetailedReadSession({
    required String bookName,
    required DateTime startTime,
    required DateTime endTime,
    required int readIteration,
  }) {
    if (!isAvailable) return false;
    try {
      rust_api.recordDetailedReadSession(
        bookName: bookName,
        startTime: startTime.millisecondsSinceEpoch,
        endTime: endTime.millisecondsSinceEpoch,
        readIteration: readIteration,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  ReadingStats? getStats(String range) {
    if (!isAvailable) return null;
    try {
      final stats = rust_api.getReadingStats(range: range);
      return ReadingStats(
        totalChars: stats.totalChars,
        totalDurationSeconds: stats.totalDurationSeconds,
        todayChars: stats.todayChars,
        todayDurationSeconds: stats.todayDurationSeconds,
        weekChars: stats.weekChars,
        daily: stats.daily
            .map(
              (item) => DailyReadingStat(
                date: item.date,
                chars: item.chars,
                durationSeconds: item.durationSeconds,
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  String? exportRecords(String format) {
    if (!isAvailable) return null;
    try {
      return rust_api.exportReadingRecords(format: format);
    } catch (_) {
      return null;
    }
  }

  @override
  String? exportDetailedReadRecords() {
    if (!isAvailable) return null;
    try {
      return rust_api.exportDetailedReadRecords();
    } catch (_) {
      return null;
    }
  }
}
