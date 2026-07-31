/// 书源编辑页清理登录 Cookie 的应用用例边界。
abstract interface class SourceLoginCookieClearPort {
  Future<void> clear(String sourceUrl);
}
