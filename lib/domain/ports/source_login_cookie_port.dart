/// 书源登录 Cookie 写入 Rust 网络会话所需的最小端口。
abstract interface class SourceLoginCookiePort {
  bool get isAvailable;

  /// 使用 [sourceUrl] 对应的书源 Cookie 桶完整替换当前 Cookie。
  void setCookie({required String sourceUrl, required String cookie});

  /// 仅清除 [sourceUrl] 对应的书源 Cookie 桶。
  void clearCookie(String sourceUrl);

  /// 返回 Rust CookieJar 对 [sourceUrl] 使用的 eTLD+1；IP 保持自身。
  String cookieDomain(String sourceUrl);
}
