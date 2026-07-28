import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'local_book_service.dart';

class RemoteArchiveImportException implements Exception {
  const RemoteArchiveImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Extracts the archive subset that the current local importer can consume.
class RemoteArchiveImportService {
  const RemoteArchiveImportService();

  Future<List<String>> extractZipBookFiles(
    List<int> bytes, {
    required Directory outputDir,
    required String archiveName,
  }) async {
    if (bytes.length > LocalBookService.maxImportBytes) {
      throw const RemoteArchiveImportException('远程压缩包超过 50MB 导入上限');
    }

    late final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (error) {
      throw RemoteArchiveImportException('ZIP 压缩包损坏或无法读取: $error');
    }
    final files = <String>[];
    var extractedBytes = 0;
    for (final entry in archive) {
      if (!entry.isFile || !_isSupportedBook(entry.name)) continue;
      final relative = _safeRelativePath(entry.name);
      if (relative == null) {
        throw RemoteArchiveImportException('压缩包包含不安全路径: ${entry.name}');
      }

      final content = entry.content as List<int>;
      extractedBytes += content.length;
      if (extractedBytes > LocalBookService.maxImportBytes) {
        throw const RemoteArchiveImportException('压缩包解压内容超过 50MB 导入上限');
      }

      final target = File(
        p.join(outputDir.path, _archivePrefix(archiveName), relative),
      );
      await target.parent.create(recursive: true);
      await target.writeAsBytes(content, flush: true);
      files.add(target.path);
    }

    if (files.isEmpty) {
      throw const RemoteArchiveImportException('压缩包内没有可导入的 TXT/EPUB 文件');
    }
    return files;
  }

  static bool _isSupportedBook(String name) =>
      RegExp(r'\.(txt|epub)$', caseSensitive: false).hasMatch(name);

  static String? _safeRelativePath(String name) {
    final normalized = name.replaceAll('\\', '/');
    if (normalized.startsWith('/') || p.isAbsolute(normalized)) return null;
    final parts = normalized.split('/');
    if (parts.any((part) => part.isEmpty || part == '.' || part == '..')) {
      return null;
    }
    return p.joinAll(parts);
  }

  static String _archivePrefix(String archiveName) {
    final base = p.basenameWithoutExtension(archiveName).trim();
    return base.isEmpty ? 'remote_archive' : base;
  }
}
