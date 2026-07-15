import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/utils/site_busy_guard.dart';

void main() {
  group('SiteBusyGuard.isSiteBusyError', () {
    test('detects SQLSTATE 1040 / Too many connections', () {
      expect(
        SiteBusyGuard.isSiteBusyError(
          Exception(
            '目录页站点异常: 数据库连接失败:SQLSTATE[08004] [1040] Too many connections',
          ),
        ),
        isTrue,
      );
      expect(
        SiteBusyGuard.isSiteBusyError('SQLSTATE[08004] [1040]'),
        isTrue,
      );
      expect(
        SiteBusyGuard.isSiteBusyError('Too many connections'),
        isTrue,
      );
    });

    test('detects 目录页站点异常', () {
      expect(
        SiteBusyGuard.isSiteBusyError('目录页站点异常: something'),
        isTrue,
      );
    });

    test('ignores unrelated errors', () {
      expect(SiteBusyGuard.isSiteBusyError('timeout'), isFalse);
      expect(SiteBusyGuard.isSiteBusyError(Exception('parse failed')), isFalse);
    });
  });

  group('SiteBusyGuard.friendlyMessage', () {
    test('maps busy errors to user-facing Chinese', () {
      expect(
        SiteBusyGuard.friendlyMessage(
          '目录页站点异常: 数据库连接失败:SQLSTATE[08004] [1040] Too many connections',
        ),
        '源站数据库繁忙，请稍后重试',
      );
    });

    test('passes through other messages', () {
      expect(SiteBusyGuard.friendlyMessage('网络超时'), '网络超时');
    });
  });

  group('SiteBusyGuard.retryOnBusy', () {
    test('retries busy errors then succeeds', () async {
      var attempts = 0;
      final result = await SiteBusyGuard.retryOnBusy(
        () async {
          attempts++;
          if (attempts < 3) {
            throw Exception(
              '目录页站点异常: SQLSTATE[08004] [1040] Too many connections',
            );
          }
          return 'ok';
        },
        delays: const [
          Duration(milliseconds: 1),
          Duration(milliseconds: 1),
        ],
      );
      expect(result, 'ok');
      expect(attempts, 3);
    });

    test('gives up after max attempts and rethrows', () async {
      var attempts = 0;
      await expectLater(
        () => SiteBusyGuard.retryOnBusy(
          () async {
            attempts++;
            throw Exception('Too many connections');
          },
          delays: const [
            Duration(milliseconds: 1),
            Duration(milliseconds: 1),
          ],
        ),
        throwsA(isA<Exception>()),
      );
      expect(attempts, 3);
    });

    test('does not retry unrelated errors', () async {
      var attempts = 0;
      await expectLater(
        () => SiteBusyGuard.retryOnBusy(
          () async {
            attempts++;
            throw Exception('parse failed');
          },
        ),
        throwsA(predicate((e) => e.toString().contains('parse failed'))),
      );
      expect(attempts, 1);
    });
  });

  group('SiteBusyGuard.dedupeByKey', () {
    test('shares one in-flight future for the same key', () async {
      var runs = 0;
      Future<int> start() => SiteBusyGuard.dedupeByKey('book-a', () async {
            runs++;
            await Future<void>.delayed(const Duration(milliseconds: 30));
            return runs;
          });

      final results = await Future.wait([start(), start(), start()]);
      expect(results, [1, 1, 1]);
      expect(runs, 1);
    });

    test('allows a new run after the previous completes', () async {
      var runs = 0;
      Future<int> start() => SiteBusyGuard.dedupeByKey('book-b', () async {
            runs++;
            return runs;
          });

      expect(await start(), 1);
      expect(await start(), 2);
      expect(runs, 2);
    });
  });
}
