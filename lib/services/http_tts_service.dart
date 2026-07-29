import 'dart:convert';
import 'dart:typed_data';

import '../domain/ports/application_binary_http_request_port.dart';
import '../domain/ports/application_http_request_port.dart';

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

  /// 稳定描述当前 HTTP TTS 配置的身份，供音频缓存区分配置使用。
  String get cacheIdentity {
    final sortedHeaders = headers.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return jsonEncode(<String, Object?>{
      'name': name,
      'url': url,
      'contentType': contentType,
      'headers': <String, String>{
        for (final entry in sortedHeaders) entry.key: entry.value,
      },
    });
  }

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
    // Legado's HttpTTS.contentType describes the response audio type.
    // Request headers are supplied independently through [headers].
    return HttpTtsRequest(
      url: raw,
      method: method,
      body: body,
      headers: resolvedHeaders,
      responseContentTypePattern: contentType?.trim(),
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
  final String? responseContentTypePattern;

  const HttpTtsRequest({
    required this.url,
    required this.method,
    this.body,
    this.headers = const {},
    this.responseContentTypePattern,
  });
}

class HttpTtsClient {
  const HttpTtsClient(this._httpPort);

  static const maxAudioBytes = 16 * 1024 * 1024;
  final ApplicationBinaryHttpRequestPort _httpPort;

  Future<Uint8List> fetchAudio(HttpTtsRequest request) async {
    final response = await _httpPort.send(
      url: request.url,
      method: request.method,
      headers: request.headers,
      body: request.body == null
          ? null
          : Uint8List.fromList(utf8.encode(request.body!)),
      timeoutSeconds: 30,
      maxResponseBytes: maxAudioBytes,
      policy: ApplicationHttpPolicy.localNetwork,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('HTTP TTS 请求失败 HTTP ${response.statusCode}');
    }
    final data = response.body;
    if (data.isEmpty) {
      throw StateError('HTTP TTS 返回空音频');
    }
    if (data.length > maxAudioBytes) {
      throw StateError('HTTP TTS 音频过大');
    }
    final responseContentType = response.contentType;
    if (responseContentType.isNotEmpty) {
      final mediaType = responseContentType.split(';').first.trim();
      if (mediaType == 'application/json' ||
          mediaType.toLowerCase().startsWith('text/')) {
        final message = utf8.decode(data, allowMalformed: true).trim();
        throw StateError(message.isEmpty ? 'HTTP TTS 返回文本错误' : message);
      }
      final pattern = request.responseContentTypePattern;
      if (pattern != null && pattern.isNotEmpty) {
        final matches = RegExp(
          pattern,
          caseSensitive: false,
        ).hasMatch(mediaType);
        if (!matches) {
          throw StateError('HTTP TTS 返回错误：$mediaType');
        }
      }
    }
    return data;
  }
}
