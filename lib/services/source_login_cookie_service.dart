import 'package:flutter/foundation.dart';

import '../domain/ports/source_login_cookie_port.dart';
import 'source_login_prefs.dart';

/// 协调 WebView Cookie 的持久化与 Rust CookieJar 写入。
abstract final class SourceLoginCookieService {
  static SourceLoginCookiePort? _port;

  static void configurePort(SourceLoginCookiePort port) {
    _port = port;
  }

  @visibleForTesting
  static void resetPort() {
    _port = null;
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
    if (port != null && port.isAvailable) {
      port.clearCookie(sourceUrl);
    }
  }
}
