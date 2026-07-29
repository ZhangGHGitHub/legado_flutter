import 'dart:convert';

import '../domain/ports/application_http_request_port.dart';

/// AI 配置页使用的 HTTP 适配器。
class AiConfigHttpService {
  const AiConfigHttpService(this._httpPort);

  final ApplicationHttpRequestPort _httpPort;

  Future<List<String>> fetchModels({
    required String apiUrl,
    String apiKey = '',
  }) async {
    final response = await _httpPort.send(
      url: modelsEndpoint(apiUrl),
      method: 'GET',
      headers: {
        if (apiKey.trim().isNotEmpty)
          'Authorization': 'Bearer ${apiKey.trim()}',
      },
      timeoutSeconds: 20,
      policy: ApplicationHttpPolicy.publicOnly,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    Object? data;
    try {
      data = jsonDecode(response.body);
    } on FormatException {
      return const [];
    }
    final ids = <String>[];
    if (data is Map && data['data'] is List) {
      for (final item in data['data'] as List) {
        if (item is Map && item['id'] != null) {
          ids.add(item['id'].toString());
        }
      }
    }
    return ids;
  }

  Future<int> testModel({
    required String apiUrl,
    required String model,
    String apiKey = '',
  }) async {
    final response = await _httpPort.send(
      url: apiUrl.trim(),
      method: 'POST',
      body: jsonEncode({
        'model': model.trim(),
        'messages': [
          {'role': 'user', 'content': 'ping'},
        ],
        'max_tokens': 8,
      }),
      headers: {
        'Content-Type': 'application/json',
        if (apiKey.trim().isNotEmpty)
          'Authorization': 'Bearer ${apiKey.trim()}',
      },
      timeoutSeconds: 30,
      policy: ApplicationHttpPolicy.publicOnly,
    );
    return response.statusCode;
  }

  static String modelsEndpoint(String chatCompletionsUrl) {
    final url = chatCompletionsUrl.trim();
    if (url.contains('/chat/completions')) {
      return url.replaceFirst('/chat/completions', '/models');
    }
    if (url.endsWith('/')) return '${url}models';
    return '$url/models';
  }
}
