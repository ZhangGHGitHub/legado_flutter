import 'dart:convert';
import 'dart:io';

import '../../domain/ports/rss_source_import_port.dart';
import '../../utils/ssrf_guard.dart';

const _rssImportTimeout = Duration(seconds: 30);
const _rssImportMaxBytes = 10 * 1024 * 1024;

/// IO adapter for RSS source URL imports.
class IoRssSourceImportPort implements RssSourceImportPort {
  const IoRssSourceImportPort();

  @override
  Future<String?> fetch(String url) async {
    var currentUrl = url.trim();
    SsrfGuard.assertPublicHttpUrl(currentUrl);
    final client = HttpClient()..connectionTimeout = _rssImportTimeout;
    try {
      for (var hop = 0; hop <= SsrfGuard.maxRedirects; hop++) {
        SsrfGuard.assertPublicHttpUrl(currentUrl);
        final uri = Uri.parse(currentUrl);
        final req = await client.getUrl(uri);
        req.followRedirects = false;
        req.maxRedirects = 0;
        final res = await req.close().timeout(_rssImportTimeout);

        if (res.statusCode >= 300 && res.statusCode < 400) {
          final location = res.headers.value(HttpHeaders.locationHeader);
          await res.drain<void>();
          if (location == null ||
              location.isEmpty ||
              hop == SsrfGuard.maxRedirects) {
            return null;
          }
          SsrfGuard.assertRedirectTarget(currentUrl, location);
          currentUrl = uri.resolve(location).toString();
          continue;
        }

        if (res.statusCode < 200 || res.statusCode >= 300) {
          await res.drain<void>();
          return null;
        }
        if (res.contentLength > _rssImportMaxBytes) return null;

        final bytes = <int>[];
        await for (final chunk in res.timeout(_rssImportTimeout)) {
          if (bytes.length + chunk.length > _rssImportMaxBytes) return null;
          bytes.addAll(chunk);
        }
        return utf8.decode(bytes);
      }
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
