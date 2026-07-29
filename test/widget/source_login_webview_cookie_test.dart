import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/features/common/app_webview_page.dart';
import 'package:legado_flutter/features/sources/source_login_page.dart';
import 'package:legado_flutter/services/source_login_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'source login WebView receives source and overriding login headers',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      const sourceUrl = 'https://www.example.com';
      await SourceLoginPrefs.saveHeader(
        sourceUrl,
        '{"Cookie":"login=1","Authorization":"Bearer token"}',
      );
      final source = BookSource.fromJson({
        'bookSourceUrl': sourceUrl,
        'bookSourceName': '测试源',
        'loginUrl': 'https://login.example.com/account',
        'header': {
          'User-Agent': 'source-agent',
          'Cookie': 'source=1',
          'X-Source': 'yes',
        },
      });

      await tester.pumpWidget(
        MaterialApp(home: SourceLoginPage(source: source)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      final webView = tester.widget<AppWebViewPage>(
        find.byType(AppWebViewPage),
      );
      expect(webView.initialUrl, 'https://login.example.com/account');
      expect(webView.headers, {
        'User-Agent': 'source-agent',
        'Cookie': 'login=1',
        'X-Source': 'yes',
        'Authorization': 'Bearer token',
      });
      expect(webView.onCookiesChanged, isNotNull);
    },
  );
}
