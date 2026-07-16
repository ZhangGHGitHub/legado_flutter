import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/utils/ssrf_guard.dart';

void main() {
  group('SsrfGuard', () {
    test('allows public https', () {
      expect(SsrfGuard.blockedReason('https://example.com/a'), isNull);
      expect(SsrfGuard.blockedReason('http://8.8.8.8/dns'), isNull);
    });

    test('blocks localhost and loopback', () {
      expect(SsrfGuard.blockedReason('http://localhost:8080/x'), isNotNull);
      expect(SsrfGuard.blockedReason('http://127.0.0.1/x'), isNotNull);
      expect(SsrfGuard.blockedReason('http://[::1]/'), isNotNull);
    });

    test('blocks private ranges', () {
      expect(SsrfGuard.blockedReason('http://10.0.0.1/'), isNotNull);
      expect(SsrfGuard.blockedReason('http://192.168.1.1/'), isNotNull);
      expect(SsrfGuard.blockedReason('http://172.16.0.1/'), isNotNull);
      expect(SsrfGuard.blockedReason('http://169.254.1.1/'), isNotNull);
    });

    test('rejects non-http schemes', () {
      expect(SsrfGuard.blockedReason('file:///tmp/x'), isNotNull);
      expect(SsrfGuard.blockedReason('ftp://example.com'), isNotNull);
    });

    test('assertRedirectTarget blocks private Location', () {
      expect(
        () => SsrfGuard.assertRedirectTarget(
          'https://example.com/a',
          'http://127.0.0.1/secret',
        ),
        throwsFormatException,
      );
      expect(
        () => SsrfGuard.assertRedirectTarget(
          'https://example.com/a',
          'https://cdn.example.com/b',
        ),
        returnsNormally,
      );
      // 相对路径解析后仍为公网
      expect(
        () => SsrfGuard.assertRedirectTarget(
          'https://example.com/a',
          '/next',
        ),
        returnsNormally,
      );
    });
  });
}
