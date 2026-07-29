import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ports/rss_sort_url_js_port.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';

/// 对齐 Jingshiro [RssSourceExtensions.sortUrls]
class RssSortUrls {
  RssSortUrls._();

  static RssSortUrlJsPort? _jsPort;

  static void configureJsPort(RssSortUrlJsPort port) {
    _jsPort = port;
  }

  @visibleForTesting
  static void resetJsPort() {
    _jsPort = null;
  }

  static String _cacheKey(RssSource source) {
    final raw = '${source.sourceUrl}|${source.sortUrl}';
    return 'rss_sort_url_${Uri.encodeComponent(raw)}';
  }

  static String _extractJs(String sortUrl) {
    final t = sortUrl.trim();
    if (t.toLowerCase().startsWith('@js:')) return t.substring(4);
    final lower = t.toLowerCase();
    if (lower.startsWith('<js>')) {
      final end = lower.lastIndexOf('</js>');
      if (end > 4) return t.substring(4, end);
      return t.substring(4);
    }
    return t;
  }

  /// 返回 `(分类名, 分类 URL)` 列表；无分类时为 `('', sourceUrl)`。
  static Future<List<(String name, String url)>> resolve(
    RssSource source,
  ) async {
    final sortUrl = source.sortUrl.trim();
    if (sortUrl.isEmpty) {
      return [('', source.sourceUrl)];
    }

    try {
      var str = sortUrl;
      final lower = sortUrl.toLowerCase();
      final isJs = lower.startsWith('<js>') || lower.startsWith('@js:');
      if (isJs) {
        final prefs = await SharedPreferences.getInstance();
        final key = _cacheKey(source);
        final cached = prefs.getString(key);
        if (cached != null && cached.trim().isNotEmpty) {
          str = cached;
        } else {
          final jsPort = _jsPort;
          if (jsPort == null || !jsPort.isAvailable) {
            throw StateError('Rust 引擎不可用，无法执行 sortUrl JS');
          }
          str = jsPort.evaluate(source: source, script: _extractJs(sortUrl));
          await prefs.setString(key, str);
        }
      }

      final out = <(String, String)>[];
      for (final sort in str.split(RegExp(r'(&&|\n)+'))) {
        final line = sort.trim();
        if (line.isEmpty) continue;
        final sep = line.indexOf('::');
        final name = sep >= 0 ? line.substring(0, sep) : line;
        final url = sep >= 0 ? line.substring(sep + 2) : '';
        if (url.isNotEmpty) {
          out.add((name, url));
        }
      }
      if (out.isEmpty) {
        out.add(('', source.sourceUrl));
      }
      return out;
    } catch (e) {
      debugPrint('[RssSortUrls] ${source.sourceName}: $e');
      return [('', source.sourceUrl)];
    }
  }

  static Future<void> clearCache(RssSource source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey(source));
  }
}
