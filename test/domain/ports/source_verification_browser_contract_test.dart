import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/source_verification_browser_port.dart';

void main() {
  group('SourceVerificationBrowserRequest Freezed contract', () {
    test('preserves request fields including nullable HTML', () {
      const request = SourceVerificationBrowserRequest(
        sourceKey: 'https://source.example',
        url: 'https://source.example/verify',
        title: '网页验证',
        html: null,
        headers: {'Referer': 'https://source.example'},
        refetchAfterSuccess: true,
      );

      expect(request.sourceKey, 'https://source.example');
      expect(request.url, 'https://source.example/verify');
      expect(request.title, '网页验证');
      expect(request.html, isNull);
      expect(request.headers, {'Referer': 'https://source.example'});
      expect(request.refetchAfterSuccess, isTrue);
    });

    test('uses value equality, copyWith, and read-only headers', () {
      const first = SourceVerificationBrowserRequest(
        sourceKey: 'source',
        url: 'https://source.example/verify',
        title: '验证',
        html: '<html>seed</html>',
        headers: {'X-Test': 'one'},
        refetchAfterSuccess: false,
      );
      const second = SourceVerificationBrowserRequest(
        sourceKey: 'source',
        url: 'https://source.example/verify',
        title: '验证',
        html: '<html>seed</html>',
        headers: {'X-Test': 'one'},
        refetchAfterSuccess: false,
      );

      expect(first, equals(second));
      expect(first.copyWith(html: null).html, isNull);
      expect(first.copyWith(refetchAfterSuccess: true).refetchAfterSuccess, isTrue);
      expect(() => first.headers['Cookie'] = 'sid=1', throwsUnsupportedError);
    });
  });

  group('SourceVerificationBrowserResult Freezed contract', () {
    test('uses value equality and copyWith', () {
      const result = SourceVerificationBrowserResult(
        finalUrl: 'https://source.example/done',
        body: '<html>done</html>',
      );

      expect(
        result,
        equals(
          const SourceVerificationBrowserResult(
            finalUrl: 'https://source.example/done',
            body: '<html>done</html>',
          ),
        ),
      );
      expect(result.copyWith(body: 'done').body, 'done');
    });
  });

  test('preserves cancellation exception text', () {
    expect(
      const SourceVerificationCancelled().toString(),
      '用户取消了书源网页验证',
    );
  });
}
