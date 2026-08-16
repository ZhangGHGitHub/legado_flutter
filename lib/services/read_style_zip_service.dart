import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/ports/application_binary_http_request_port.dart';
import '../domain/ports/application_http_request_port.dart';
import '../models/read_style_config.dart';

/// 阅读排版 zip 导入/导出（对齐 legado `ReadBookConfig.import` / `exportConfig`）
///
/// zip 内至少含 `readConfig.json`；可选字体与背景图片文件。
class ReadStyleZipService {
  ReadStyleZipService(this._httpPort);

  final ApplicationBinaryHttpRequestPort _httpPort;
  static const configFileName = 'readConfig.json';
  static const maxDownloadBytes = 64 * 1024 * 1024;
  static const maxArchiveFileBytes = 32 * 1024 * 1024;
  static const maxArchiveTotalBytes = 128 * 1024 * 1024;

  Future<Directory> _bgDir() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory(p.join(root.path, 'read_bg'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _fontDir() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory(p.join(root.path, 'font'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// 从 zip 字节解析并落盘字体/背景；返回 Config。
  Future<ReadStyleConfig> importBytes(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    _validateArchive(archive);
    ArchiveFile? configEntry;
    for (final f in archive.files) {
      if (!f.isFile) continue;
      final name = p.basename(f.name);
      if (name == configFileName) {
        configEntry = f;
        break;
      }
    }
    if (configEntry == null) {
      throw const FormatException('zip 中缺少 readConfig.json');
    }
    final jsonText = utf8.decode(_archiveBytes(configEntry));
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map) {
      throw const FormatException('readConfig.json 须为对象');
    }
    var config = ReadStyleConfig.fromJson(Map<String, dynamic>.from(decoded));

    // 字体
    if (config.textFont.isNotEmpty) {
      final fontName = p.basename(config.textFont);
      final fontBytes = _findArchiveBytes(archive, fontName);
      if (fontBytes != null) {
        final fontDir = await _fontDir();
        final dest = File(p.join(fontDir.path, fontName));
        if (!await dest.exists()) {
          await dest.writeAsBytes(fontBytes);
        }
        config = config.copyWith(textFont: dest.path);
      } else {
        config = config.copyWith(textFont: '');
      }
    }

    // 白天背景图
    if (config.bgType == 2 && config.bgStr.isNotEmpty) {
      final bgName = p.basename(config.bgStr);
      final path = await _materializeBg(archive, bgName);
      config = config.copyWith(bgStr: path ?? bgName);
    }

    // 夜间背景图
    if (config.bgTypeNight == 2 && config.bgStrNight.isNotEmpty) {
      final bgName = p.basename(config.bgStrNight);
      final path = await _materializeBg(archive, bgName);
      config = config.copyWith(bgStrNight: path ?? bgName);
    }

    return config;
  }

  Future<String?> _materializeBg(Archive archive, String bgName) async {
    final bytes = _findArchiveBytes(archive, bgName);
    if (bytes == null) return null;
    final dir = await _bgDir();
    final dest = File(p.join(dir.path, bgName));
    if (!await dest.exists()) {
      await dest.writeAsBytes(bytes);
    }
    return dest.path;
  }

  Uint8List? _findArchiveBytes(Archive archive, String fileName) {
    for (final f in archive.files) {
      if (!f.isFile) continue;
      if (p.basename(f.name) == fileName) {
        return _archiveBytes(f);
      }
    }
    return null;
  }

  void _validateArchive(Archive archive) {
    var totalBytes = 0;
    for (final file in archive.files) {
      final normalizedName = file.name.replaceAll('\\', '/');
      final isAbsolute =
          normalizedName.startsWith('/') ||
          RegExp(r'^[A-Za-z]:/').hasMatch(normalizedName);
      final hasParentTraversal = normalizedName
          .split('/')
          .any((segment) => segment == '..');
      if (isAbsolute || hasParentTraversal) {
        throw FormatException('zip 包含不安全路径：${file.name}');
      }
      if (!file.isFile) continue;
      if (file.size < 0 || file.size > maxArchiveFileBytes) {
        throw FormatException('zip 单文件解压后不得超过 32 MiB：${file.name}');
      }
      totalBytes += file.size;
      if (totalBytes > maxArchiveTotalBytes) {
        throw const FormatException('zip 解压后总量不得超过 128 MiB');
      }
    }
  }

  Uint8List _archiveBytes(ArchiveFile file) {
    final bytes = file.content;
    if (bytes.length > maxArchiveFileBytes) {
      throw FormatException('zip 单文件解压后不得超过 32 MiB：${file.name}');
    }
    return Uint8List.fromList(bytes);
  }

  Future<ReadStyleConfig> importFile(File file) async {
    return importBytes(await file.readAsBytes());
  }

  Future<ReadStyleConfig> importFromUrl(String url) async {
    final trimmedUrl = url.trim();
    final response = await _httpPort.send(
      url: trimmedUrl,
      method: 'GET',
      timeoutSeconds: 30,
      maxResponseBytes: maxDownloadBytes,
      policy: ApplicationHttpPolicy.localNetwork,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        '主题 URL 请求失败（HTTP ${response.statusCode}）',
        uri: Uri.tryParse(trimmedUrl),
      );
    }
    if (response.body.isEmpty) {
      throw const FormatException('主题 URL 返回空内容');
    }
    return importBytes(response.body);
  }

  /// 导出为 zip 字节（含 readConfig.json + 可选背景文件）
  Future<Uint8List> exportBytes(ReadStyleConfig config) async {
    var export = config;
    final archive = Archive();

    Future<void> addBgIfNeeded(String pathOrName, int bgType) async {
      if (bgType != 2 || pathOrName.isEmpty) return;
      final file = File(
        pathOrName.contains(p.separator)
            ? pathOrName
            : p.join((await _bgDir()).path, pathOrName),
      );
      if (!await file.exists()) return;
      final name = p.basename(file.path);
      archive.addFile(
        ArchiveFile(name, await file.length(), await file.readAsBytes()),
      );
    }

    // 导出时字体字段只写文件名（对齐 legado）
    if (export.textFont.isNotEmpty) {
      final fontFile = File(export.textFont);
      if (await fontFile.exists()) {
        final name = p.basename(fontFile.path);
        archive.addFile(
          ArchiveFile(
            name,
            await fontFile.length(),
            await fontFile.readAsBytes(),
          ),
        );
        export = export.copyWith(textFont: name);
      }
    }

    await addBgIfNeeded(export.bgStr, export.bgType);
    await addBgIfNeeded(export.bgStrNight, export.bgTypeNight);

    // 背景路径在 JSON 中改为文件名
    if (export.bgType == 2) {
      export = export.copyWith(bgStr: p.basename(export.bgStr));
    }
    if (export.bgTypeNight == 2) {
      export = export.copyWith(bgStrNight: p.basename(export.bgStrNight));
    }

    final jsonBytes = utf8.encode(jsonEncode(export.toJson()));
    archive.addFile(ArchiveFile(configFileName, jsonBytes.length, jsonBytes));

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }
}
