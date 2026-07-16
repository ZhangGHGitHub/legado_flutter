/// 书源 / 网络请求用的基础 SSRF 防护（不约束 Web API 本机监听）。
///
/// 限制（刻意不做 DNS 解析）：仅校验 URL 字面量 host（localhost / 私网 IP 段等）。
/// 重定向场景请用 [assertRedirectTarget] 对每跳 Location 再校验；
/// 无法阻止「公网域名解析到内网」类 DNS rebinding。
class SsrfGuard {
  SsrfGuard._();

  /// 跟随重定向时的最大跳数（与 Rust HTTP / Dio 约定一致）
  static const int maxRedirects = 5;

  /// 若 [url] 指向明显内网 / 回环 / 链路本地目标则抛出 [FormatException]。
  static void assertPublicHttpUrl(String url) {
    final reason = blockedReason(url);
    if (reason != null) {
      throw FormatException(reason);
    }
  }

  /// 校验重定向 Location（可相对路径）；以 [currentUrl] 解析后再做 host 检查。
  static void assertRedirectTarget(String currentUrl, String location) {
    final current = Uri.tryParse(currentUrl.trim());
    if (current == null) {
      throw const FormatException('无效的当前 URL');
    }
    final resolved = current.resolve(location.trim());
    assertPublicHttpUrl(resolved.toString());
  }

  /// 返回拦截原因；允许则返回 null。
  static String? blockedReason(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return '无效的 URL';
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return '仅允许 http/https 请求';
    }
    final host = uri.host.toLowerCase();
    if (host == 'localhost' || host == '0.0.0.0' || host == '::1') {
      return '禁止访问本机/回环地址（SSRF 防护）: $host';
    }
    if (_isBlockedIp(host)) {
      return '禁止访问内网/私有地址（SSRF 防护）: $host';
    }
    return null;
  }

  static bool _isBlockedIp(String host) {
    // IPv6 简写
    if (host == '::1') return true;
    if (host.startsWith('fe80:') || host.startsWith('fc') || host.startsWith('fd')) {
      return true;
    }

    final parts = host.split('.');
    if (parts.length != 4) return false;
    final nums = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0 || n > 255) return false;
      nums.add(n);
    }
    final a = nums[0];
    final b = nums[1];
    // 127.0.0.0/8
    if (a == 127) return true;
    // 10.0.0.0/8
    if (a == 10) return true;
    // 192.168.0.0/16
    if (a == 192 && b == 168) return true;
    // 172.16.0.0/12
    if (a == 172 && b >= 16 && b <= 31) return true;
    // 169.254.0.0/16 link-local
    if (a == 169 && b == 254) return true;
    // 0.0.0.0/8
    if (a == 0) return true;
    return false;
  }
}
