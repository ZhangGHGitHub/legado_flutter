import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/startup/startup_task_runner.dart';

void main() {
  group('StartupTaskReport', () {
    final startedAt = DateTime.utc(2026, 8, 3, 9);
    final finishedAt = DateTime.utc(2026, 8, 3, 9, 0, 2);

    test('preserves running state without elapsed time', () {
      final report = StartupTaskReport(
        id: 'startup.restore',
        status: StartupTaskStatus.running,
        attempt: 1,
        startedAt: startedAt,
      );

      expect(report.isTerminal, isFalse);
      expect(report.elapsed, isNull);
    });

    test('preserves terminal states and elapsed duration', () {
      for (final status in const [
        StartupTaskStatus.succeeded,
        StartupTaskStatus.failed,
        StartupTaskStatus.skipped,
      ]) {
        final report = StartupTaskReport(
          id: 'startup.restore',
          status: status,
          attempt: 2,
          startedAt: startedAt,
          finishedAt: finishedAt,
        );

        expect(report.isTerminal, isTrue);
        expect(report.elapsed, const Duration(seconds: 2));
      }
    });

    test('keeps error and stack trace when copied', () {
      final error = StateError('offline');
      final stackTrace = StackTrace.current;
      final report = StartupTaskReport(
        id: 'startup.restore',
        status: StartupTaskStatus.failed,
        attempt: 3,
        startedAt: startedAt,
        finishedAt: finishedAt,
        error: error,
        stackTrace: stackTrace,
      );

      final copied = report.copyWith(attempt: 4);

      expect(copied.error, same(error));
      expect(copied.stackTrace, same(stackTrace));
      expect(copied.attempt, 4);
      expect(copied.status, StartupTaskStatus.failed);
    });

    test('uses value equality for reports with the same task data', () {
      final first = StartupTaskReport(
        id: 'startup.restore',
        status: StartupTaskStatus.succeeded,
        attempt: 1,
        startedAt: startedAt,
        finishedAt: finishedAt,
      );
      final second = StartupTaskReport(
        id: 'startup.restore',
        status: StartupTaskStatus.succeeded,
        attempt: 1,
        startedAt: startedAt,
        finishedAt: finishedAt,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}
