class BookReadingStats {
  const BookReadingStats({
    required this.readChars,
    required this.durationSeconds,
    required this.startDate,
    required this.lastDate,
  });

  final int readChars;
  final int durationSeconds;
  final String? startDate;
  final String? lastDate;
}
