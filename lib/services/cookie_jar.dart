import 'package:flutter/foundation.dart';

/// A simple cookie store for Legado-compatible cookie management.
///
/// Stores cookies per domain, auto-extracts from Set-Cookie headers,
/// and provides JS-accessible functions via `cookie.*`.
class CookieJar {
  static final CookieJar _instance = CookieJar._internal();
  factory CookieJar() => _instance;
  CookieJar._internal();

  // Domain -> cookie name -> (value, domain, path, expiry)
  final Map<String, Map<String, _Cookie>> _cookies = {};

  /// Extract and store cookies from HTTP response headers
  void saveFromHeaders(String url, Map<String, List<String>> headers) {
    final domain = _extractDomain(url);
    if (domain.isEmpty) return;

    final setCookieHeaders = headers['set-cookie'] ?? headers['Set-Cookie'] ?? <String>[];
    for (final header in setCookieHeaders) {
      _parseAndStore(domain, header);
    }
  }

  /// Get cookies for a URL as a Cookie header string
  String getCookie(String url) {
    final domain = _extractDomain(url);
    if (domain.isEmpty) return '';

    final now = DateTime.now().millisecondsSinceEpoch;
    final parts = <String>[];

    // Collect cookies from the domain and its parent domains
    final domains = _getDomainChain(domain);
    for (final d in domains) {
      final domainCookies = _cookies[d];
      if (domainCookies == null) continue;

      for (final entry in domainCookies.entries) {
        final cookie = entry.value;
        // Check expiry
        if (cookie.expiry > 0 && now > cookie.expiry) {
          continue; // expired
        }
        // Check path (simplified: always include if no path restriction)
        parts.add('${entry.key}=${cookie.value}');
      }
    }

    return parts.join('; ');
  }

  /// Set a cookie manually (for JS: cookie.setCookie(url, cookieStr))
  void setCookie(String url, String cookieStr) {
    final domain = _extractDomain(url);
    if (domain.isEmpty) return;
    _parseAndStore(domain, cookieStr);
  }

  /// Get a specific cookie key value (for JS: cookie.getKey(url, key))
  String? getKey(String url, String key) {
    final domain = _extractDomain(url);
    if (domain.isEmpty) return null;

    final domains = _getDomainChain(domain);
    for (final d in domains) {
      final domainCookies = _cookies[d];
      if (domainCookies == null) continue;
      final cookie = domainCookies[key];
      if (cookie != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (cookie.expiry > 0 && now > cookie.expiry) continue;
        return cookie.value;
      }
    }
    return null;
  }

  /// Replace cookie for a domain (for JS: cookie.replaceCookie(url, cookieStr))
  void replaceCookie(String url, String cookieStr) {
    final domain = _extractDomain(url);
    if (domain.isEmpty) return;
    // Clear existing cookies for this domain
    _cookies.remove(domain);
    // Then set new ones
    _parseAndStore(domain, cookieStr);
  }

  /// Remove cookies for a domain (for JS: cookie.removeCookie(url))
  void removeCookie(String url) {
    final domain = _extractDomain(url);
    if (domain.isEmpty) return;
    _cookies.remove(domain);
  }

  /// Clear all cookies
  void clear() {
    _cookies.clear();
  }

  // ── Private helpers ──

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.toLowerCase();
    } catch (_) {
      return '';
    }
  }

  /// Get domain chain: "a.b.c" -> ["a.b.c", "b.c"]
  List<String> _getDomainChain(String domain) {
    final parts = domain.split('.');
    final chain = <String>[];
    for (int i = 0; i < parts.length - 1; i++) {
      chain.add(parts.skip(i).join('.'));
    }
    return chain;
  }

  void _parseAndStore(String domain, String header) {
    // Parse: name=value; Path=/; Domain=.example.com; Max-Age=3600; Secure; HttpOnly
    final parts = header.split(';');
    if (parts.isEmpty) return;

    // First part: name=value
    final firstEq = parts[0].indexOf('=');
    if (firstEq <= 0) return;
    final name = parts[0].substring(0, firstEq).trim();
    final value = parts[0].substring(firstEq + 1).trim();
    if (name.isEmpty) return;

    String cookieDomain = domain;
    String path = '/';
    int maxAge = -1;
    int expiry = 0;

    for (int i = 1; i < parts.length; i++) {
      final part = parts[i].trim();
      final eqIdx = part.indexOf('=');
      if (eqIdx > 0) {
        final key = part.substring(0, eqIdx).trim().toLowerCase();
        final val = part.substring(eqIdx + 1).trim();
        switch (key) {
          case 'domain':
            cookieDomain = val.startsWith('.') ? val.substring(1) : val;
            cookieDomain = cookieDomain.toLowerCase();
            break;
          case 'path':
            path = val;
            break;
          case 'max-age':
            maxAge = int.tryParse(val) ?? -1;
            break;
          case 'expires':
            // Parse HTTP date - simplified
            try {
              final parsed = DateTime.tryParse(val.replaceAll('-', ' '));
              if (parsed != null) expiry = parsed.millisecondsSinceEpoch;
            } catch (_) {}
            break;
        }
      }
    }

    if (maxAge > 0) {
      expiry = DateTime.now().millisecondsSinceEpoch + (maxAge * 1000);
    }

    final cookie = _Cookie(
      value: value,
      domain: cookieDomain,
      path: path,
      expiry: expiry,
    );

    _cookies.putIfAbsent(cookieDomain, () => {});
    _cookies[cookieDomain]![name] = cookie;

    debugPrint('  Cookie saved: $name=$value for $cookieDomain');
  }
}

/// Internal cookie data
class _Cookie {
  final String value;
  final String domain;
  final String path;
  final int expiry; // 0 = session (no expiry)

  const _Cookie({
    required this.value,
    this.domain = '',
    this.path = '/',
    this.expiry = 0,
  });
}
