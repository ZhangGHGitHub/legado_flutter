import 'dart:typed_data';

/// HTTP TTS 音频缓存端口。
///
/// 缓存实现负责把配置身份、文本和速度组合成稳定的缓存身份；调用方
/// 只提供获取音频的函数，因此请求失败不会产生可复用的缓存内容。
abstract interface class HttpTtsCachePort {
  Future<Uint8List> getOrFetch({
    required String configurationKey,
    required String text,
    required double speed,
    required Future<Uint8List> Function() fetch,
  });

  Future<void> clear();
}
