import '../../domain/ports/public_text_fetch_port.dart';
import '../../domain/ports/rss_source_import_port.dart';
import '../../utils/ssrf_guard.dart';

/// 通过统一公开文本端口读取 RSS 订阅源列表。
class PublicTextRssSourceImportPort implements RssSourceImportPort {
  const PublicTextRssSourceImportPort(this._textFetchPort);

  final PublicTextFetchPort _textFetchPort;

  @override
  Future<String?> fetch(String url) async {
    final requestUrl = url.trim();
    SsrfGuard.assertPublicHttpUrl(requestUrl);
    try {
      return await _textFetchPort.fetch(requestUrl);
    } catch (_) {
      return null;
    }
  }
}
