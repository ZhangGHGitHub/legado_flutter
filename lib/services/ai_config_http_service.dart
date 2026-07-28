import 'package:dio/dio.dart';

/// AI 配置页使用的 HTTP 适配器。
class AiConfigHttpService {
  AiConfigHttpService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<List<String>> fetchModels({
    required String apiUrl,
    String apiKey = '',
  }) async {
    final response = await _dio.get<dynamic>(
      modelsEndpoint(apiUrl),
      options: Options(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          if (apiKey.trim().isNotEmpty)
            'Authorization': 'Bearer ${apiKey.trim()}',
        },
      ),
    );
    final data = response.data;
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
    final response = await _dio.post<dynamic>(
      apiUrl.trim(),
      data: {
        'model': model.trim(),
        'messages': [
          {'role': 'user', 'content': 'ping'},
        ],
        'max_tokens': 8,
      },
      options: Options(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          if (apiKey.trim().isNotEmpty)
            'Authorization': 'Bearer ${apiKey.trim()}',
        },
        validateStatus: (_) => true,
      ),
    );
    return response.statusCode ?? 0;
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
