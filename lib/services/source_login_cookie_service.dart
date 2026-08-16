import 'package:flutter/foundation.dart';

import '../domain/ports/source_login_cookie_port.dart';
import '../domain/ports/source_login_web_cookie_port.dart';
import 'source_login_prefs.dart';

/// 协调 WebView Cookie 的持久化与 Rust CookieJar 写入。
abstract final class SourceLoginCookieService {
  static SourceLoginCookiePort? _port;
  static SourceLoginWebCookiePort? _webCookiePort;

  static void configurePort(SourceLoginCookiePort port) {
    _port = port;
  }

  static void configureWebCookiePort(SourceLoginWebCookiePort port) {
    _webCookiePort = port;
  }

  @visibleForTesting
  static void resetPort() {
    _port = null;
    _webCookiePort = null;
  }

  static Future<void> capture({
    required String sourceUrl,
    required String cookie,
  }) async {
    await SourceLoginPrefs.saveCookie(sourceUrl, cookie);
    final port = _port;
    if (port != null && port.isAvailable) {
      port.setCookie(sourceUrl: sourceUrl, cookie: cookie);
    }
  }

  static Future<void> restore(String sourceUrl) async {
    final cookie = await SourceLoginPrefs.loadCookie(sourceUrl);
    final port = _port;
    if (cookie != null && port != null && port.isAvailable) {
      port.setCookie(sourceUrl: sourceUrl, cookie: cookie);
    }
  }

  static Future<void> clear(String sourceUrl) async {
    await SourceLoginPrefs.clearCookie(sourceUrl);
    final port = _port;
    var registrableDomain = Uri.tryParse(sourceUrl)?.host ?? '';
    if (port != null && port.isAvailable) {
      try {
        registrableDomain = port.cookieDomain(sourceUrl);
      } catch (_) {}
      port.clearCookie(sourceUrl);
    }
    final webCookiePort = _webCookiePort;
    if (webCookiePort != null && webCookiePort.isSupported) {
      try {
        await webCookiePort.clearForSource(
          sourceUrl: sourceUrl,
          registrableDomain: registrableDomain,
        );
      } catch (e) {
        debugPrint('[SourceLogin] 平台 WebView Cookie 清除失败: $e');
      }
    }
  }
}
