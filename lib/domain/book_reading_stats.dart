import 'package:freezed_annotation/freezed_annotation.dart';

part 'book_reading_stats.freezed.dart';

@freezed
class BookReadingStats with _$BookReadingStats {
  const factory BookReadingStats({
    required int readChars,
    required int durationSeconds,
    required String? startDate,
    required String? lastDate,
    @Default(0) int readingDays,
  }) = _BookReadingStats;
}
