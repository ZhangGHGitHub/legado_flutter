import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/source_verification_browser_port.dart';
import 'package:legado_flutter/features/common/app_webview_page.dart';
import 'package:legado_flutter/features/common/navigator_source_verification_browser_port.dart';

void main() {
  testWidgets(
    'serializes verification pages and persists cookies before reply',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
      );

      final cookieWrites = <({String sourceKey, String cookie})>[];
      final pageResults = <Completer<AppWebViewResult?>>[
        Completer<AppWebViewResult?>(),
        Completer<AppWebViewResult?>(),
      ];
      var opened = 0;
      final navigators = <NavigatorState>[];
      final port = NavigatorSourceVerificationBrowserPort(
        navigatorKey: navigatorKey,
        captureCookie: ({required sourceKey, required cookie}) async {
          cookieWrites.add((sourceKey: sourceKey, cookie: cookie));
        },
        isWebViewSupported: () => true,
        pageOpener: (navigator, request, onCookiesChanged) async {
          final index = opened++;
          navigators.add(navigator);
          await onCookiesChanged(request.url, 'sid=${index + 1}');
          return pageResults[index].future;
        },
      );
      const request = SourceVerificationBrowserRequest(
        sourceKey: 'https://www.example.com',
        url: 'https://www.example.com/verify',
        title: '验证',
        html: null,
        headers: {'X-Test': '1'},
        refetchAfterSuccess: false,
      );

      final first = port.openAndWait(request);
      final second = port.openAndWait(request);
      await tester.pump();
      expect(opened, 1);
      expect(navigators.single, same(navigatorKey.currentState));
      expect(cookieWrites, [(sourceKey: request.sourceKey, cookie: 'sid=1')]);

      pageResults[0].complete(
        const AppWebViewResult(
          finalUrl: 'https://www.example.com/done-1',
          body: 'one',
        ),
      );
      expect((await first).body, 'one');
      await tester.pump();
      expect(opened, 2);
      expect(cookieWrites.last.cookie, 'sid=2');

      pageResults[1].complete(
        const AppWebViewResult(
          finalUrl: 'https://www.example.com/done-2',
          body: 'two',
        ),
      );
      expect((await second).finalUrl, 'https://www.example.com/done-2');
    },
  );

  testWidgets('treats route dismissal as an explicit cancellation', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
    );
    final port = NavigatorSourceVerificationBrowserPort(
      navigatorKey: navigatorKey,
      captureCookie: ({required sourceKey, required cookie}) async {},
      isWebViewSupported: () => true,
      pageOpener: (_, _, _) async => null,
    );

    expect(
      port.openAndWait(
        const SourceVerificationBrowserRequest(
          sourceKey: 'https://example.com',
          url: 'https://example.com/verify',
          title: '验证',
          html: null,
          headers: {},
          refetchAfterSuccess: true,
        ),
      ),
      throwsA(isA<SourceVerificationCancelled>()),
    );
  });
}
