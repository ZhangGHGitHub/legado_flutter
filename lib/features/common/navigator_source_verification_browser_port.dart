import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/ports/source_verification_browser_port.dart';
import 'app_webview_page.dart';

typedef SourceVerificationPageOpener =
    Future<AppWebViewResult?> Function(
      NavigatorState navigator,
      SourceVerificationBrowserRequest request,
      AppWebViewCookieCallback onCookiesChanged,
    );
typedef SourceVerificationWebViewSupport = bool Function();
typedef SourceVerificationCookieCapture =
    Future<void> Function({required String sourceKey, required String cookie});

class NavigatorSourceVerificationBrowserPort
    implements SourceVerificationBrowserPort {
  NavigatorSourceVerificationBrowserPort({
    required GlobalKey<NavigatorState> navigatorKey,
    required SourceVerificationCookieCapture captureCookie,
    SourceVerificationPageOpener? pageOpener,
    SourceVerificationWebViewSupport? isWebViewSupported,
  }) : _navigatorKey = navigatorKey,
       _captureCookie = captureCookie,
       _pageOpener = pageOpener ?? _openPage,
       _isWebViewSupported =
           isWebViewSupported ?? (() => AppWebViewPage.isWebViewSupported);

  final GlobalKey<NavigatorState> _navigatorKey;
  final SourceVerificationCookieCapture _captureCookie;
  final SourceVerificationPageOpener _pageOpener;
  final SourceVerificationWebViewSupport _isWebViewSupported;
  Future<void> _queue = Future<void>.value();

  @override
  Future<SourceVerificationBrowserResult> openAndWait(
    SourceVerificationBrowserRequest request,
  ) {
    final result = Completer<SourceVerificationBrowserResult>();
    _queue = _queue
        .catchError((Object _) {})
        .then((_) => _open(request, result));
    return result.future;
  }

  Future<void> _open(
    SourceVerificationBrowserRequest request,
    Completer<SourceVerificationBrowserResult> completer,
  ) async {
    try {
      if (!_isWebViewSupported()) {
        throw UnsupportedError('当前平台不支持书源网页验证');
      }
      final navigator = await _waitForNavigator();
      final pageResult = await _pageOpener(
        navigator,
        request,
        (pageUrl, cookie) =>
            _captureCookie(sourceKey: request.sourceKey, cookie: cookie),
      );
      if (pageResult == null) throw const SourceVerificationCancelled();
      completer.complete(
        SourceVerificationBrowserResult(
          finalUrl: pageResult.finalUrl,
          body: pageResult.body,
        ),
      );
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    }
  }

  Future<NavigatorState> _waitForNavigator() async {
    for (var attempt = 0; attempt < 100; attempt++) {
      final navigator = _navigatorKey.currentState;
      if (navigator != null) return navigator;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    throw StateError('应用导航尚未就绪');
  }

  static Future<AppWebViewResult?> _openPage(
    NavigatorState navigator,
    SourceVerificationBrowserRequest request,
    AppWebViewCookieCallback onCookiesChanged,
  ) {
    return AppWebViewPage.openForResult(
      navigator.context,
      title: request.title,
      url: request.url,
      html: request.html,
      headers: request.headers,
      onCookiesChanged: onCookiesChanged,
    );
  }
}
