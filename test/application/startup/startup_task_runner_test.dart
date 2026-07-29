import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/startup/startup_task_runner.dart';

void main() {
  test(
    'merges concurrent calls and does not repeat a successful task',
    () async {
      final reports = <StartupTaskReport>[];
      final runner = StartupTaskRunner(onReport: reports.add);
      var calls = 0;

      final first = runner.run('bookshelf.load', () async {
        calls++;
        await Future<void>.delayed(Duration.zero);
      });
      final second = runner.run('bookshelf.load', () async => calls++);

      final result = await first;
      expect(await second, same(result));
      expect(
        await runner.run('bookshelf.load', () async => calls++),
        same(result),
      );
      expect(calls, 1);
      expect(reports.map((report) => report.status), [
        StartupTaskStatus.running,
        StartupTaskStatus.succeeded,
      ]);
    },
  );

  test('failed tasks can be retried with an incremented attempt', () async {
    final runner = StartupTaskRunner();
    var calls = 0;

    final failed = await runner.run('webdav.initialize', () async {
      calls++;
      throw StateError('offline');
    });
    final succeeded = await runner.run('webdav.initialize', () async {
      calls++;
    });

    expect(failed.status, StartupTaskStatus.failed);
    expect(succeeded.status, StartupTaskStatus.succeeded);
    expect(succeeded.attempt, 2);
    expect(calls, 2);
  });

  test('timeouts are isolated and reported as failures', () async {
    final runner = StartupTaskRunner();

    final report = await runner.run(
      'network.restore',
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
      timeout: const Duration(milliseconds: 1),
    );

    expect(report.status, StartupTaskStatus.failed);
    expect(report.error, isA<TimeoutException>());
  });

  test('skipped tasks are observable without executing an action', () async {
    final runner = StartupTaskRunner();

    final report = await runner.skip('book_progress.sync');

    expect(report.status, StartupTaskStatus.skipped);
    expect(runner.reports['book_progress.sync'], same(report));
  });
}
