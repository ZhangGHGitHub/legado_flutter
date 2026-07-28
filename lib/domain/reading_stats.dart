class DailyReadingStat {
  const DailyReadingStat({
    required this.date,
    required this.chars,
    required this.durationSeconds,
  });

  final String date;
  final int chars;
  final int durationSeconds;
}

class ReadingStats {
  const ReadingStats({
    required this.totalChars,
    required this.totalDurationSeconds,
    required this.todayChars,
    required this.todayDurationSeconds,
    required this.weekChars,
    required this.daily,
  });

  final int totalChars;
  final int totalDurationSeconds;
  final int todayChars;
  final int todayDurationSeconds;
  final int weekChars;
  final List<DailyReadingStat> daily;
}
