/// 书源登录在平台 WebView CookieStore 中执行定域清除所需的最小端口。
abstract interface class SourceLoginWebCookiePort {
  bool get isSupported;

  Future<void> clearForSource({
    required String sourceUrl,
    required String registrableDomain,
  });
}
