import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/reader/reading_session_tracker.dart';

void main() {
  group('ReadingSessionDelta Freezed contract', () {
    test('preserves values and supports immutable copies', () {
      final endedAt = DateTime(2026, 8, 3, 12, 1, 2);
      final delta = ReadingSessionDelta(
        chars: 1200,
        durationSeconds: 30,
        endedAt: endedAt,
      );

      expect(delta.chars, 1200);
      expect(delta.durationSeconds, 30);
      expect(delta.endedAt, endedAt);
      expect(
        delta.copyWith(chars: 1600),
        ReadingSessionDelta(chars: 1600, durationSeconds: 30, endedAt: endedAt),
      );
      expect(delta, isNot(delta.copyWith(chars: 1600)));
    });

    test('uses value equality for equivalent deltas', () {
      final endedAt = DateTime(2026, 8, 3, 12, 1, 2);

      expect(
        ReadingSessionDelta(chars: 0, durationSeconds: 15, endedAt: endedAt),
        ReadingSessionDelta(chars: 0, durationSeconds: 15, endedAt: endedAt),
      );
    });
  });

  group('DetailedReadingSession Freezed contract', () {
    test('retains trimmed book name, read iteration, and DateTime values', () {
      final startTime = DateTime(2026, 8, 3, 12);
      final endTime = startTime.add(const Duration(minutes: 2, seconds: 1));
      final session = DetailedReadingSession(
        bookName: '测试书',
        startTime: startTime,
        endTime: endTime,
        readIteration: 7,
      );

      expect(session.bookName, '测试书');
      expect(session.startTime, startTime);
      expect(session.endTime, endTime);
      expect(session.readIteration, 7);
      expect(session.copyWith(readIteration: 8).readIteration, 8);
      expect(session.copyWith(readIteration: 8).bookName, '测试书');
    });

    test(
      'keeps equivalent sessions equal without changing DateTime semantics',
      () {
        final startTime = DateTime(2026, 8, 3, 12);
        final endTime = startTime.add(const Duration(seconds: 121));
        final first = DetailedReadingSession(
          bookName: '测试书',
          startTime: startTime,
          endTime: endTime,
          readIteration: 2,
        );

        expect(
          first,
          DetailedReadingSession(
            bookName: '测试书',
            startTime: startTime,
            endTime: endTime,
            readIteration: 2,
          ),
        );
      },
    );
  });
}
