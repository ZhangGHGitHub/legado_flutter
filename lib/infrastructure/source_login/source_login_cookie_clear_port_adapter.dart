import '../../application/source_login/source_login_cookie_clear_port.dart';
import '../../services/source_login_cookie_service.dart';

/// 保留既有 SharedPreferences、Rust CookieJar 和 WebView 清理顺序。
final class SourceLoginCookieClearPortAdapter
    implements SourceLoginCookieClearPort {
  const SourceLoginCookieClearPortAdapter();

  @override
  Future<void> clear(String sourceUrl) =>
      SourceLoginCookieService.clear(sourceUrl);
}
