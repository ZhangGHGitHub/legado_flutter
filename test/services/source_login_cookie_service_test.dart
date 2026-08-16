import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/source_login_cookie_port.dart';
import 'package:legado_flutter/domain/ports/source_login_web_cookie_port.dart';
import 'package:legado_flutter/services/source_login_cookie_service.dart';
import 'package:legado_flutter/services/source_login_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSourceLoginCookiePort implements SourceLoginCookiePort {
  @override
  bool isAvailable = true;

  final sets = <({String sourceUrl, String cookie})>[];
  final clears = <String>[];

  @override
  void setCookie({required String sourceUrl, required String cookie}) {
    sets.add((sourceUrl: sourceUrl, cookie: cookie));
  }

  @override
  void clearCookie(String sourceUrl) {
    clears.add(sourceUrl);
  }

  @override
  String cookieDomain(String sourceUrl) => 'example.com';
}

class _FakeSourceLoginWebCookiePort implements SourceLoginWebCookiePort {
  @override
  bool isSupported = true;

  final clears = <({String sourceUrl, String registrableDomain})>[];

  @override
  Future<void> clearForSource({
    required String sourceUrl,
    required String registrableDomain,
  }) async {
    clears.add((sourceUrl: sourceUrl, registrableDomain: registrableDomain));
  }
}

void main() {
  const sourceUrl = 'https://www.example.com';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SourceLoginCookieService.resetPort();
  });

  tearDown(SourceLoginCookieService.resetPort);

  test(
    'captures the full WebView cookie string and writes Rust immediately',
    () async {
      final port = _FakeSourceLoginCookiePort();
      SourceLoginCookieService.configurePort(port);

      await SourceLoginCookieService.capture(
        sourceUrl: sourceUrl,
        cookie: 'sid=1; token=abc',
      );

      expect(await SourceLoginPrefs.loadCookie(sourceUrl), 'sid=1; token=abc');
      expect(port.sets, [(sourceUrl: sourceUrl, cookie: 'sid=1; token=abc')]);
    },
  );

  test(
    'restores persisted cookies and preserves an empty replacement',
    () async {
      final port = _FakeSourceLoginCookiePort();
      SourceLoginCookieService.configurePort(port);
      await SourceLoginPrefs.saveCookie(sourceUrl, '');

      await SourceLoginCookieService.restore(sourceUrl);

      expect(port.sets, [(sourceUrl: sourceUrl, cookie: '')]);
    },
  );

  test('clears only the requested source cookie bucket', () async {
    final port = _FakeSourceLoginCookiePort();
    final webPort = _FakeSourceLoginWebCookiePort();
    SourceLoginCookieService.configurePort(port);
    SourceLoginCookieService.configureWebCookiePort(webPort);
    await SourceLoginPrefs.saveCookie(sourceUrl, 'sid=1');

    await SourceLoginCookieService.clear(sourceUrl);

    expect(await SourceLoginPrefs.loadCookie(sourceUrl), isNull);
    expect(port.clears, [sourceUrl]);
    expect(webPort.clears, [
      (sourceUrl: sourceUrl, registrableDomain: 'example.com'),
    ]);
  });
}
