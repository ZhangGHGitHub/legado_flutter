import 'dart:typed_data';

import '../../application/reader/reader_image_cache_port.dart';
import '../../domain/ports/application_binary_http_request_port.dart';
import '../../services/reader_image_cache.dart' as service;

/// 懒初始化图片缓存，避免缓存目录探测阻塞首屏。
final class ReaderImageCachePortAdapter implements ReaderImageCachePort {
  ReaderImageCachePortAdapter(this._httpPort);

  final ApplicationBinaryHttpRequestPort _httpPort;
  Future<service.ReaderImageCache?>? _cacheFuture;

  Future<service.ReaderImageCache?> _cache() {
    return _cacheFuture ??= _createCache();
  }

  Future<service.ReaderImageCache?> _createCache() async {
    try {
      return await service.ReaderImageCache.createDefault(_httpPort);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Uint8List?> loadBytes(
    String source, {
    Map<String, String> headers = const {},
  }) async {
    final cache = await _cache();
    return cache?.loadBytes(source, headers: headers);
  }

  @override
  Future<ReaderImageSize?> getSize(
    String source, {
    Map<String, String> headers = const {},
  }) async {
    final cache = await _cache();
    final size = await cache?.getSize(source, headers: headers);
    if (size == null) return null;
    return ReaderImageSize(width: size.width, height: size.height);
  }
}
