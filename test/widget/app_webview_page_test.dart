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
}
