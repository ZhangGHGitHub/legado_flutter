import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/reading_record_service.dart';

void main() {
  test('tracker commits only new chars and elapsed duration', () {
    var now = DateTime(2026, 7, 22, 12);
    final tracker = ReadingSessionTracker(clock: () => now);

    tracker.start();
    tracker.addChars(1200);
    now = now.add(const Duration(seconds: 30));

    final first = tracker.pending();
    expect(first?.chars, 1200);
    expect(first?.durationSeconds, 30);
    tracker.commit(first!);

    now = now.add(const Duration(seconds: 15));
    final second = tracker.pending();
    expect(second?.chars, 0);
    expect(second?.durationSeconds, 15);
  });

  test('tracker start is idempotent and ignores non-positive chars', () {
    var now = DateTime(2026, 7, 22, 12);
    final tracker = ReadingSessionTracker(clock: () => now);

    tracker.start();
    now = now.add(const Duration(seconds: 10));
    tracker.start();
    tracker.addChars(0);
    tracker.addChars(-10);
    now = now.add(const Duration(seconds: 20));

    final pending = tracker.pending();
    expect(pending?.chars, 0);
    expect(pending?.durationSeconds, 30);
  });

  test('detailed tracker filters sessions at two minutes', () {
    var now = DateTime(2026, 7, 22, 12);
    final tracker = DetailedReadingSessionTracker(
      bookName: ' 测试书 ',
      readIteration: 2,
      clock: () => now,
    );

    tracker.start();
    now = now.add(const Duration(minutes: 2));
    expect(tracker.stop(), isNull);

    tracker.start();
    now = now.add(const Duration(minutes: 2, seconds: 1));
    final session = tracker.stop();
    expect(session?.bookName, '测试书');
    expect(session?.readIteration, 2);
  });
}
