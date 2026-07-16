import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../pages/reader/reader_settings.dart';

/// 自定义阅读字体加载（主题 zip / 本地字体文件 → [FontLoader]）
///
/// 默认字体对齐 Jingshiro [ChapterProvider.getTypeface]：
/// `textFont` 为空时用 `Typeface.SANS_SERIF`（及 SERIF / MONOSPACE），
/// 避免 Flutter 桌面「西文+中文 fallback」混用导致有的字粗、有的字细。
abstract final class ReaderFontLoader {
  static final Map<String, String> _pathToFamily = {};
  static final Set<String> _loading = {};

  static final _fontExtensions = {'.ttf', '.otf', '.ttc', '.woff', '.woff2'};

  /// 对齐 AppConfig.systemTypefaces：0 默认无衬线 / 1 衬线 / 2 等宽
  static const systemSans = '';
  static const systemSerif = 'serif';
  static const systemMono = 'monospace';

  static bool isFontFilePath(String value) {
    if (value.isEmpty) return false;
    if (value == systemSerif || value == systemMono) return false;
    final ext = p.extension(value).toLowerCase();
    if (_fontExtensions.contains(ext)) return true;
    return value.contains(p.separator) || value.contains('/');
  }

  static String displayName(String fontFamily) {
    if (fontFamily.isEmpty) return '系统默认';
    if (fontFamily == systemSerif) return '衬线';
    if (fontFamily == systemMono) return '等宽';
    if (isFontFilePath(fontFamily)) {
      return p.basenameWithoutExtension(fontFamily);
    }
    return fontFamily;
  }

  /// 当前平台适合正文的无衬线族（含完整中文，避免混字重）。
  static String platformSansFamily() {
    if (kIsWeb) return 'sans-serif';
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return 'Microsoft YaHei';
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
        return 'PingFang SC';
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return 'sans-serif';
      case TargetPlatform.linux:
        return 'Noto Sans CJK SC';
    }
  }

  static String platformSerifFamily() {
    if (kIsWeb) return 'serif';
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return 'SimSun';
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
        return 'Songti SC';
      default:
        return 'serif';
    }
  }

  static String platformMonoFamily() {
    if (kIsWeb) return 'monospace';
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return 'Consolas';
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
        return 'Menlo';
      default:
        return 'monospace';
    }
  }

  /// CJK 回退链：主字体缺字时仍尽量同一风格。
  static List<String> cjkFallbackFamilies() {
    if (kIsWeb) {
      return const ['Noto Sans SC', 'PingFang SC', 'Microsoft YaHei', 'sans-serif'];
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return const [
          'Microsoft YaHei UI',
          'Microsoft YaHei',
          'SimHei',
          'Noto Sans SC',
          'sans-serif',
        ];
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
        return const [
          'PingFang SC',
          'Heiti SC',
          'STHeiti',
          'Noto Sans SC',
          'sans-serif',
        ];
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return const [
          'Noto Sans CJK SC',
          'Noto Sans SC',
          'Source Han Sans SC',
          'sans-serif',
        ];
      case TargetPlatform.linux:
        return const [
          'Noto Sans CJK SC',
          'Noto Sans SC',
          'WenQuanYi Micro Hei',
          'sans-serif',
        ];
    }
  }

  /// 将设置中的 fontFamily 解析为 Flutter 可用的族名（空=平台无衬线）。
  static String resolveFamilySync(String fontFamily) {
    if (fontFamily.isEmpty) return platformSansFamily();
    if (fontFamily == systemSerif) return platformSerifFamily();
    if (fontFamily == systemMono) return platformMonoFamily();
    if (isFontFilePath(fontFamily)) {
      return _pathToFamily[fontFamily] ?? platformSansFamily();
    }
    return fontFamily;
  }

  /// 构建阅读正文 [TextStyle]（对齐 ChapterProvider contentPaint）。
  static TextStyle contentTextStyle({
    required ReaderSettings settings,
    required Color color,
    String? resolvedFamily,
  }) {
    final family = resolvedFamily ?? resolveFamilySync(settings.fontFamily);
    // Jingshiro Paint.letterSpacing 为 em；Flutter 为逻辑像素。
    final letterPx = settings.letterSpacing * settings.fontSize;
    return TextStyle(
      fontSize: settings.fontSize,
      height: settings.lineHeight,
      color: color,
      fontFamily: family,
      fontFamilyFallback: cjkFallbackFamilies(),
      fontWeight: settings.fontWeight.flutterWeight,
      letterSpacing: letterPx,
    );
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
  static Future<String> resolveFamily(String fontFamily) async {
    if (fontFamily.isEmpty) return platformSansFamily();
    if (fontFamily == systemSerif) return platformSerifFamily();
    if (fontFamily == systemMono) return platformMonoFamily();
    if (!isFontFilePath(fontFamily)) return fontFamily;
    return (await ensureLoaded(fontFamily)) ?? platformSansFamily();
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
