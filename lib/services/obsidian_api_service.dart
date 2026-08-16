import '../domain/ports/application_http_request_port.dart';

/// Obsidian Local REST API 的 HTTP 适配器。
class ObsidianApiService {
  const ObsidianApiService(this._httpPort);

  final ApplicationHttpRequestPort _httpPort;

  Future<int> testConnection({required String url, String apiKey = ''}) async {
    final response = await _httpPort.send(
      url: url.trim(),
      method: 'GET',
      headers: {
        if (apiKey.trim().isNotEmpty)
          'Authorization': 'Bearer ${apiKey.trim()}',
      },
      timeoutSeconds: 15,
      policy: ApplicationHttpPolicy.localNetwork,
    );
    return response.statusCode;
  }

  Future<String> exportMarkdown({
    required String url,
    required String markdown,
    required String fileName,
    String apiKey = '',
  }) async {
    final target = url.contains('{path}')
        ? url.replaceAll('{path}', Uri.encodeComponent(fileName))
        : (url.endsWith('/') ? '$url$fileName' : '$url/$fileName');
    final response = await _httpPort.send(
      url: target,
      method: 'PUT',
      body: markdown,
      headers: {
        'Content-Type': 'text/markdown',
        if (apiKey.trim().isNotEmpty)
          'Authorization': 'Bearer ${apiKey.trim()}',
      },
      timeoutSeconds: 30,
      policy: ApplicationHttpPolicy.localNetwork,
    );
    final code = response.statusCode;
    if (code >= 200 && code < 300) {
      return '已通过 REST API 导出（HTTP $code）';
    }
    throw Exception('HTTP $code: ${response.body}');
  }
}
