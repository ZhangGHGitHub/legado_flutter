import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 自定义阅读字体加载（主题 zip / 本地字体文件 → [FontLoader]）
abstract final class ReaderFontLoader {
  static final Map<String, String> _pathToFamily = {};
  static final Set<String> _loading = {};

  static final _fontExtensions = {'.ttf', '.otf', '.ttc', '.woff', '.woff2'};

  static bool isFontFilePath(String value) {
    if (value.isEmpty) return false;
    if (value == 'serif' || value == 'monospace') return false;
    final ext = p.extension(value).toLowerCase();
    if (_fontExtensions.contains(ext)) return true;
    return value.contains(p.separator) || value.contains('/');
  }

  static String displayName(String fontFamily) {
    if (fontFamily.isEmpty) return '系统默认';
    if (fontFamily == 'serif') return '衬线';
    if (fontFamily == 'monospace') return '等宽';
    if (isFontFilePath(fontFamily)) {
      return p.basenameWithoutExtension(fontFamily);
    }
    return fontFamily;
  }

  /// 将文件路径注册为 Flutter 字体族；返回可用于 [TextStyle.fontFamily] 的族名。
  static Future<String?> ensureLoaded(String fontPath) async {
    if (!isFontFilePath(fontPath)) return fontPath.isEmpty ? null : fontPath;
    final file = File(fontPath);
    if (!await file.exists()) return null;

    final cached = _pathToFamily[fontPath];
    if (cached != null) return cached;
    if (_loading.contains(fontPath)) {
      while (_loading.contains(fontPath)) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
      return _pathToFamily[fontPath];
    }

    _loading.add(fontPath);
    try {
      final bytes = await file.readAsBytes();
      final stem = p.basenameWithoutExtension(fontPath);
      final family = 'legado_$stem';
      final loader = FontLoader(family);
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      _pathToFamily[fontPath] = family;
      return family;
    } catch (_) {
      return null;
    } finally {
      _loading.remove(fontPath);
    }
  }

  /// 解析 [TextStyle.fontFamily]：内置族名原样返回，文件路径经 FontLoader 转换。
  static Future<String?> resolveFamily(String fontFamily) async {
    if (fontFamily.isEmpty) return null;
    if (!isFontFilePath(fontFamily)) return fontFamily;
    return ensureLoaded(fontFamily);
  }

  static Future<Directory> fontDirectory() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory(p.join(root.path, 'font'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// 已落盘自定义字体（zip 导入等），按修改时间倒序。
  static Future<List<File>> listCustomFontFiles() async {
    final dir = await fontDirectory();
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final ext = p.extension(entity.path).toLowerCase();
      if (_fontExtensions.contains(ext)) files.add(entity);
    }
    files.sort(
      (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
    );
    return files;
  }
}
