import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book_reading_stats.dart';
import 'package:legado_flutter/domain/reading_stats.dart';

void main() {
  group('reading stats Freezed contract', () {
    test('book stats preserve optional dates and reading days', () {
      const stats = BookReadingStats(
        readChars: 1200,
        durationSeconds: 360,
        startDate: '2026-08-01',
        lastDate: null,
        readingDays: 3,
      );

      expect(
        stats.copyWith(readingDays: 4),
        const BookReadingStats(
          readChars: 1200,
          durationSeconds: 360,
          startDate: '2026-08-01',
          lastDate: null,
          readingDays: 4,
        ),
      );
      expect(
        const BookReadingStats(
          readChars: 1,
          durationSeconds: 1,
          startDate: null,
          lastDate: null,
        ).readingDays,
        0,
      );
    });

    test('aggregate stats retain immutable daily values', () {
      const daily = DailyReadingStat(
        date: '2026-08-02',
        chars: 42,
        durationSeconds: 12,
      );
      const stats = ReadingStats(
        totalChars: 42,
        totalDurationSeconds: 12,
        todayChars: 42,
        todayDurationSeconds: 12,
        weekChars: 42,
        daily: [daily],
      );

      expect(stats.copyWith(weekChars: 100).daily, [daily]);
      expect(
        stats,
        const ReadingStats(
          totalChars: 42,
          totalDurationSeconds: 12,
          todayChars: 42,
          todayDurationSeconds: 12,
          weekChars: 42,
          daily: [daily],
        ),
      );
    });
  });
}
