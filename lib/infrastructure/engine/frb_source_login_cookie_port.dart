import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/source_login_cookie_port.dart';
import '../../src/rust/api/network.dart' as network_api;

/// Rust CookieJar 的书源登录 Cookie 适配器。
class FrbSourceLoginCookiePort implements SourceLoginCookiePort {
  const FrbSourceLoginCookiePort();

  @override
  bool get isAvailable => LegadoEngineBridge.isAvailable;

  @override
  void setCookie({required String sourceUrl, required String cookie}) {
    if (!isAvailable) return;
    network_api.setSourceCookie(sourceUrl: sourceUrl, cookie: cookie);
  }

  @override
  void clearCookie(String sourceUrl) {
    if (!isAvailable) return;
    network_api.clearSourceCookie(sourceUrl: sourceUrl);
  }

  @override
  String cookieDomain(String sourceUrl) {
    if (!isAvailable) return Uri.tryParse(sourceUrl)?.host ?? '';
    return network_api.sourceCookieDomain(sourceUrl: sourceUrl);
  }
}
