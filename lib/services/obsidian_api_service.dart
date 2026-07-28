import 'package:dio/dio.dart';

/// Obsidian Local REST API 的 HTTP 适配器。
class ObsidianApiService {
  ObsidianApiService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<int> testConnection({required String url, String apiKey = ''}) async {
    final response = await _dio.get<dynamic>(
      url.trim(),
      options: Options(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          if (apiKey.trim().isNotEmpty)
            'Authorization': 'Bearer ${apiKey.trim()}',
        },
        validateStatus: (_) => true,
      ),
    );
    return response.statusCode ?? 0;
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
    final response = await _dio.put<dynamic>(
      target,
      data: markdown,
      options: Options(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'text/markdown',
          if (apiKey.trim().isNotEmpty)
            'Authorization': 'Bearer ${apiKey.trim()}',
        },
      ),
    );
    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      return '已通过 REST API 导出（HTTP $code）';
    }
    throw Exception('HTTP $code: ${response.data}');
  }
}
