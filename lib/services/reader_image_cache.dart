import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'app_paths.dart';

typedef ReaderImageDownloader =
    Future<Uint8List> Function(Uri uri, Map<String, String> headers);

class ReaderImageSize {
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

/// Fetches, caches, and inspects reader raster images without UI dependencies.
class ReaderImageCache {
  final Directory directory;
  final ReaderImageDownloader downloader;
  final _memory = <String, Uint8List>{};
  final _inFlight = <String, Future<Uint8List?>>{};

  ReaderImageCache({required this.directory, required this.downloader});

  static Future<ReaderImageCache> createDefault() async {
    final bookCache = await AppPaths.bookCacheDir();
    final directory = Directory(p.join(bookCache.path, 'reader_images'));
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    return ReaderImageCache(
      directory: directory,
      downloader: (uri, headers) async {
        final response = await dio.get<List<int>>(
          uri.toString(),
          options: Options(responseType: ResponseType.bytes, headers: headers),
        );
        final data = response.data;
        if (data == null || data.isEmpty) {
          throw StateError('empty reader image response');
        }
        return Uint8List.fromList(data);
      },
    );
  }

  Future<Uint8List?> loadBytes(
    String source, {
    Map<String, String> headers = const {},
  }) async {
    final uri = Uri.tryParse(source);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    final key = _cacheKey(source, headers);
    final memory = _memory[key];
    if (memory != null) return memory;
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = _loadUncached(key, uri, headers);
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlight[key], future)) {
        _inFlight.remove(key);
      }
    }
  }

  Future<ReaderImageSize?> getSize(
    String source, {
    Map<String, String> headers = const {},
  }) async {
    final bytes = await loadBytes(source, headers: headers);
    if (bytes == null || bytes.isEmpty) return null;
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded != null && decoded.width >= 1 && decoded.height >= 1) {
        return ReaderImageSize(width: decoded.width, height: decoded.height);
      }
      return _decodeSvgSize(bytes);
    } catch (_) {
      return _decodeSvgSize(bytes);
    }
  }

  ReaderImageSize? _decodeSvgSize(Uint8List bytes) {
    try {
      final text = utf8.decode(bytes, allowMalformed: true);
      final document = XmlDocument.parse(text);
      final root = document.rootElement;
      if (root.name.local.toLowerCase() != 'svg') return null;

      final viewBox = _parseSvgViewBox(root.getAttribute('viewBox'));
      final width = _parseSvgLength(root.getAttribute('width')) ?? viewBox?.$1;
      final height =
          _parseSvgLength(root.getAttribute('height')) ?? viewBox?.$2;
      if (width == null || height == null || width <= 0 || height <= 0) {
        return null;
      }
      return ReaderImageSize(width: width.toInt(), height: height.toInt());
    } catch (_) {
      return null;
    }
  }

  double? _parseSvgLength(String? value) {
    if (value == null) return null;
    final match = RegExp(
      r'^\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+))\s*(px|pt|pc|mm|cm|in)?\s*$',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return null;
    final number = double.tryParse(match.group(1)!);
    if (number == null) return null;
    return switch (match.group(2)?.toLowerCase()) {
      null || 'px' => number,
      'pt' => number * 96 / 72,
      'pc' => number * 16,
      'mm' => number * 96 / 25.4,
      'cm' => number * 96 / 2.54,
      'in' => number * 96,
      _ => null,
    };
  }

  (double, double)? _parseSvgViewBox(String? value) {
    if (value == null) return null;
    final values = value
        .trim()
        .split(RegExp(r'[\s,]+'))
        .map(double.tryParse)
        .toList();
    if (values.length != 4 || values.any((item) => item == null)) {
      return null;
    }
    final width = values[2]!;
    final height = values[3]!;
    if (width <= 0 || height <= 0) return null;
    return (width, height);
  }

  Future<Uint8List?> _loadUncached(
    String key,
    Uri uri,
    Map<String, String> headers,
  ) async {
    final file = File(p.join(directory.path, '${_fileKey(key)}.image'));
    try {
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          _memory[key] = bytes;
          return bytes;
        }
      }
    } catch (_) {
      // A corrupt/unreadable cache entry is replaced by a fresh download.
    }

    try {
      final bytes = await downloader(uri, Map.unmodifiable(headers));
      if (bytes.isEmpty) return null;
      await directory.create(recursive: true);
      final temp = File('${file.path}.tmp');
      await temp.writeAsBytes(bytes, flush: true);
      try {
        await temp.rename(file.path);
      } catch (_) {
        if (!await file.exists()) rethrow;
        await temp.delete();
      }
      _memory[key] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  String _cacheKey(String source, Map<String, String> headers) {
    final entries = headers.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final headerKey = entries.map((entry) => '${entry.key}=${entry.value}');
    return '$source\n${headerKey.join('\n')}';
  }

  String _fileKey(String key) => sha256.convert(utf8.encode(key)).toString();
}
