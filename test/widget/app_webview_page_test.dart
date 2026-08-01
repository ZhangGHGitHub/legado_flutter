import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/features/common/app_webview_page.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  test(
    'flattens effective WebView cookies with later names replacing earlier',
    () {
      final header = AppWebViewPage.cookieHeaderFor(const [
        WebViewCookie(name: 'sid', value: 'old', domain: 'example.com'),
        WebViewCookie(name: 'token', value: 'abc=123', domain: 'example.com'),
        WebViewCookie(name: 'sid', value: 'new', domain: 'example.com'),
      ]);

      expect(header, 'sid=new; token=abc=123');
    },
  );

  test('normalizes JavaScript string results without corrupting raw HTML', () {
    expect(
      AppWebViewPageStateTestApi.htmlFromJavaScriptResult(
        '"<html>\\n<body>ok</body></html>"',
      ),
      '<html>\n<body>ok</body></html>',
    );
    expect(
      AppWebViewPageStateTestApi.htmlFromJavaScriptResult('<html>raw</html>'),
      '<html>raw</html>',
    );
  });

  test('does not deliver cookie updates after dispose', () async {
    final delivered = <String>[];

    final skipped =
        await AppWebViewPageStateTestApi.deliverCookieHeaderIfActive(
          isActive: false,
          pageUrl: 'https://example.com',
          cookieHeader: 'sid=1',
          onCookiesChanged: (pageUrl, cookie) async {
            delivered.add('$pageUrl $cookie');
          },
        );

    expect(skipped, isFalse);
    expect(delivered, isEmpty);
  });

  test('delivers cookie updates while active', () async {
    final delivered = <String>[];

    final sent = await AppWebViewPageStateTestApi.deliverCookieHeaderIfActive(
      isActive: true,
      pageUrl: 'https://example.com',
      cookieHeader: 'sid=1',
      onCookiesChanged: (pageUrl, cookie) async {
        delivered.add('$pageUrl $cookie');
      },
    );

    expect(sent, isTrue);
    expect(delivered, ['https://example.com sid=1']);
  });
}
