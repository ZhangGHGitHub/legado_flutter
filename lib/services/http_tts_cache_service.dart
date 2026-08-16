import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/ports/http_tts_cache_port.dart';

/// 基于应用临时目录的 HTTP TTS 音频缓存。
///
/// [directory] 用于测试或平台组合层注入实际缓存目录。默认目录与原版
/// 一致，位于系统临时目录下的 `httpTTS` 子目录。
class HttpTtsCacheService implements HttpTtsCachePort {
  HttpTtsCacheService({Directory? directory}) : _directory = directory;

  final Directory? _directory;
  Future<Directory>? _directoryFuture;
  final Map<String, Future<Uint8List>> _inFlight = {};
  int _generation = 0;

  /// 返回由配置身份、文本和速度共同决定的稳定文件名主体。
  String cacheKey({
    required String configurationKey,
    required String text,
    required double speed,
  }) {
    final value = jsonEncode(<String, Object>{
      'configuration': configurationKey,
      'text': text,
      'speed': speed.toString(),
    });
    return sha256.convert(utf8.encode(value)).toString();
  }

  @override
  Future<Uint8List> getOrFetch({
    required String configurationKey,
    required String text,
    required double speed,
    required Future<Uint8List> Function() fetch,
  }) async {
    final key = cacheKey(
      configurationKey: configurationKey,
      text: text,
      speed: speed,
    );
    final directory = await _cacheDirectory();
    final file = File(p.join(directory.path, '$key.mp3'));
    final cached = await _read(file);
    if (cached != null) return cached;

    final pending = _inFlight[key];
    if (pending != null) return pending;

    final generation = _generation;
    late final Future<Uint8List> request;
    request = () async {
      // Another caller may have completed the write while this request was
      // being scheduled; avoid fetching in that case.
      final rechecked = await _read(file);
      if (rechecked != null) return rechecked;

      final audio = await fetch();
      if (audio.isEmpty) {
        throw StateError('HTTP TTS 返回空音频');
      }
      if (generation == _generation) {
        try {
          await _writeAtomically(file, audio);
          if (generation != _generation) {
            await _deleteIfExists(file);
          }
        } catch (_) {
          // Cache storage is an optimization. A successful fetch remains
          // usable even when the temporary directory cannot be written.
        }
      }
      return audio;
    }();
    _inFlight[key] = request;
    try {
      return await request;
    } finally {
      if (identical(_inFlight[key], request)) {
        _inFlight.remove(key);
      }
    }
  }

  @override
  Future<void> clear() async {
    _generation++;
    _inFlight.clear();
    final directory = await _cacheDirectory();
    if (!await directory.exists()) return;
    await for (final entity in directory.list(followLinks: false)) {
      try {
        await entity.delete(recursive: true);
      } catch (_) {
        // A stale cache entry must not prevent the remaining entries from
        // being removed.
      }
    }
  }

  Future<Directory> _cacheDirectory() {
    final configured = _directory;
    if (configured != null) return Future.value(configured);
    return _directoryFuture ??= () async {
      final temporary = await getTemporaryDirectory();
      return Directory(p.join(temporary.path, 'httpTTS'));
    }();
  }

  Future<Uint8List?> _read(File file) async {
    try {
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        await file.delete();
        return null;
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeAtomically(File file, Uint8List bytes) async {
    await file.parent.create(recursive: true);
    final temporary = File(
      '${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(file.path);
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) await file.delete();
  }
}
