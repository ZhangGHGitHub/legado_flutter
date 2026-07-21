import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// HTTP TTS 书源配置。URL 兼容 Legado 常用的 `{{speakText}}`、
/// `{{speakSpeed}}` 和 `{{speed}}` 占位符。
class HttpTtsConfig {
  final String name;
  final String url;
  final String? contentType;
  final Map<String, String> headers;

  const HttpTtsConfig({
    this.name = 'HTTP TTS',
    required this.url,
    this.contentType,
    this.headers = const {},
  });

  bool get isConfigured => url.trim().isNotEmpty;

  HttpTtsRequest resolve(String text, double speed) {
    var raw = url.trim();
    var method = 'GET';
    String? body;
    final resolvedHeaders = <String, String>{...headers};

    if (raw.startsWith('{')) {
      final config = _decodeJson(raw);
      raw = (config['url'] as String? ?? '').trim();
      method = (config['method'] as String? ?? method).toUpperCase();
      body = config['body'] as String?;
      _mergeHeaders(resolvedHeaders, config['headers']);
    } else {
      final comma = raw.indexOf(',{');
      if (comma >= 0) {
        final config = _decodeJson(raw.substring(comma + 1));
        raw = raw.substring(0, comma).trim();
        method = (config['method'] as String? ?? method).toUpperCase();
        body = config['body'] as String?;
        _mergeHeaders(resolvedHeaders, config['headers']);
      }
    }

    final encodedText = Uri.encodeComponent(text);
    raw = _replaceUrlPlaceholders(raw, encodedText, speed);
    if (body != null) {
      body = body
          .replaceAll('{{speakText}}', text)
          .replaceAll('{{key}}', text)
          .replaceAll('{{speakSpeed}}', speed.toString())
          .replaceAll('{{speed}}', speed.toString());
    }
    if (contentType != null && contentType!.trim().isNotEmpty) {
      resolvedHeaders.putIfAbsent('Content-Type', () => contentType!.trim());
    }
    return HttpTtsRequest(
      url: raw,
      method: method,
      body: body,
      headers: resolvedHeaders,
    );
  }

  static String _replaceUrlPlaceholders(
    String raw,
    String encodedText,
    double speed,
  ) {
    return raw
        .replaceAll('{{speakText}}', encodedText)
        .replaceAll('{{key}}', encodedText)
        .replaceAll('{{speakSpeed}}', speed.toString())
        .replaceAll('{{speed}}', speed.toString());
  }

  static Map<String, dynamic> _decodeJson(String raw) {
    try {
      final value = jsonDecode(raw);
      return value is Map ? Map<String, dynamic>.from(value) : {};
    } catch (_) {
      return {};
    }
  }

  static void _mergeHeaders(Map<String, String> target, dynamic value) {
    if (value is! Map) return;
    for (final entry in value.entries) {
      target[entry.key.toString()] = entry.value.toString();
    }
  }
}

class HttpTtsRequest {
  final String url;
  final String method;
  final String? body;
  final Map<String, String> headers;

  const HttpTtsRequest({
    required this.url,
    required this.method,
    this.body,
    this.headers = const {},
  });
}

class HttpTtsClient {
  HttpTtsClient({Dio? dio}) : _dio = dio ?? Dio();

  static const maxAudioBytes = 16 * 1024 * 1024;
  final Dio _dio;

  Future<Uint8List> fetchAudio(HttpTtsRequest request) async {
    final response = await _dio.request<List<int>>(
      request.url,
      data: request.body,
      options: Options(
        method: request.method,
        headers: request.headers,
        responseType: ResponseType.bytes,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
        followRedirects: true,
        maxRedirects: 5,
      ),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('HTTP TTS 返回空音频');
    }
    if (data.length > maxAudioBytes) {
      throw StateError('HTTP TTS 音频过大');
    }
    return Uint8List.fromList(data);
  }
}
