import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/ports/application_binary_http_request_port.dart';
import '../domain/ports/application_http_request_port.dart';

typedef RemoteImageErrorBuilder =
    Widget Function(BuildContext context, Object error, StackTrace? stackTrace);

class RemoteBinaryImage extends StatelessWidget {
  const RemoteBinaryImage({
    super.key,
    required this.url,
    this.headers = const {},
    this.policy = ApplicationHttpPolicy.localNetwork,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.placeholderBuilder,
    this.errorBuilder,
  });

  static const maxResponseBytes = 32 * 1024 * 1024;

  final String url;
  final Map<String, String> headers;
  final ApplicationHttpPolicy policy;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final WidgetBuilder? placeholderBuilder;
  final RemoteImageErrorBuilder? errorBuilder;

  static void clearMemoryCache() => _RemoteImageMemoryCache.clear();

  static Future<void> prefetch(
    BuildContext context, {
    required String url,
    Map<String, String> headers = const {},
    ApplicationHttpPolicy policy = ApplicationHttpPolicy.localNetwork,
  }) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return;
    final port = context.read<ApplicationBinaryHttpRequestPort>();
    await _RemoteImageMemoryCache.load(
      port: port,
      url: trimmedUrl,
      headers: headers,
      policy: policy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return _placeholder(context);

    ApplicationBinaryHttpRequestPort port;
    try {
      port = context.read<ApplicationBinaryHttpRequestPort>();
    } catch (error, stackTrace) {
      return _error(context, error, stackTrace);
    }

    return FutureBuilder<Uint8List>(
      future: _RemoteImageMemoryCache.load(
        port: port,
        url: trimmedUrl,
        headers: headers,
        policy: policy,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _error(context, snapshot.error!, snapshot.stackTrace);
        }
        final bytes = snapshot.data;
        if (bytes == null) return _placeholder(context);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) =>
              _error(context, error, stackTrace),
        );
      },
    );
  }

  Widget _placeholder(BuildContext context) {
    return placeholderBuilder?.call(context) ??
        SizedBox(width: width, height: height);
  }

  Widget _error(BuildContext context, Object error, StackTrace? stackTrace) {
    return errorBuilder?.call(context, error, stackTrace) ??
        _placeholder(context);
  }
}

abstract final class _RemoteImageMemoryCache {
  static const _maxEntries = 128;
  static const _maxBytes = 64 * 1024 * 1024;
  static final _completed = <String, Uint8List>{};
  static final _inFlight = <String, Future<Uint8List>>{};
  static int _completedBytes = 0;

  static Future<Uint8List> load({
    required ApplicationBinaryHttpRequestPort port,
    required String url,
    required Map<String, String> headers,
    required ApplicationHttpPolicy policy,
  }) {
    final key = _key(url, headers, policy);
    final cached = _completed.remove(key);
    if (cached != null) {
      _completed[key] = cached;
      return Future.value(cached);
    }
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = _fetch(port, url, headers, policy).then((bytes) {
      _store(key, bytes);
      return bytes;
    });
    _inFlight[key] = future;
    future.whenComplete(() {
      if (identical(_inFlight[key], future)) _inFlight.remove(key);
    }).ignore();
    return future;
  }

  static Future<Uint8List> _fetch(
    ApplicationBinaryHttpRequestPort port,
    String url,
    Map<String, String> headers,
    ApplicationHttpPolicy policy,
  ) async {
    final response = await port.send(
      url: url,
      method: 'GET',
      headers: headers,
      timeoutSeconds: 20,
      maxResponseBytes: RemoteBinaryImage.maxResponseBytes,
      policy: policy,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('远程图片请求失败 HTTP ${response.statusCode}');
    }
    if (response.body.isEmpty) throw StateError('远程图片响应为空');
    return response.body;
  }

  static void _store(String key, Uint8List bytes) {
    if (bytes.length > _maxBytes) return;
    final previous = _completed.remove(key);
    if (previous != null) _completedBytes -= previous.length;
    while (_completed.isNotEmpty &&
        (_completed.length >= _maxEntries ||
            _completedBytes + bytes.length > _maxBytes)) {
      final oldest = _completed.keys.first;
      _completedBytes -= _completed.remove(oldest)!.length;
    }
    _completed[key] = bytes;
    _completedBytes += bytes.length;
  }

  static String _key(
    String url,
    Map<String, String> headers,
    ApplicationHttpPolicy policy,
  ) {
    final sortedHeaders = headers.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '${policy.name}\n$url\n${sortedHeaders.map((entry) => '${entry.key}:${entry.value}').join('\n')}';
  }

  static void clear() {
    _completed.clear();
    _completedBytes = 0;
  }
}
