import 'dart:typed_data';

/// 阅读器图片缓存的应用层边界。
abstract interface class ReaderImageCachePort {
  Future<Uint8List?> loadBytes(
    String source, {
    Map<String, String> headers,
  });

  Future<ReaderImageSize?> getSize(
    String source, {
    Map<String, String> headers,
  });
}

final class ReaderImageSize {
  final int width;
  final int height;

  const ReaderImageSize({required this.width, required this.height});

  @override
  bool operator ==(Object other) =>
      other is ReaderImageSize &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(width, height);
}
