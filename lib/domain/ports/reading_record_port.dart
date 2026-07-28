import '../reading_stats.dart';

/// Reading statistics and persistence operations used by the application layer.
///
/// Reading timers and character accounting remain in the Flutter session
/// layer. This port only owns persistence of the already validated delta.
abstract interface class ReadingRecordPort {
  bool get isAvailable;

  bool recordReading({
    required String bookId,
    required String bookName,
    required int chars,
    required int durationSeconds,
  });

  bool recordDetailedReadSession({
    required String bookName,
    required DateTime startTime,
    required DateTime endTime,
    required int readIteration,
  });

  ReadingStats? getStats(String range);

  String? exportRecords(String format);

  String? exportDetailedReadRecords();
}
