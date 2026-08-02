import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading_stats.freezed.dart';

@freezed
class DailyReadingStat with _$DailyReadingStat {
  const factory DailyReadingStat({
    required String date,
    required int chars,
    required int durationSeconds,
  }) = _DailyReadingStat;
}

@freezed
class ReadingStats with _$ReadingStats {
  const factory ReadingStats({
    required int totalChars,
    required int totalDurationSeconds,
    required int todayChars,
    required int todayDurationSeconds,
    required int weekChars,
    required List<DailyReadingStat> daily,
  }) = _ReadingStats;
}
