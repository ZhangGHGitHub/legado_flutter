import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/ports/remote_archive_parser_port.dart';

class RemoteArchiveImportException implements Exception {
  const RemoteArchiveImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Extracts the archive subset that the current local importer can consume.
class RemoteArchiveImportService {
  const RemoteArchiveImportService({required RemoteArchiveParserPort parser})
    : _parser = parser;

  final RemoteArchiveParserPort _parser;

  Future<List<String>> extractZipBookFiles(
    List<int> bytes, {
    required Directory outputDir,
    required String archiveName,
  }) async {
    if (!_parser.isAvailable) {
      throw const RemoteArchiveImportException('Rust 引擎未初始化，无法解析远程 ZIP');
    }

    late final List<RemoteArchiveBookFile> files;
    try {
      files = _parser.parseZipBookFiles(bytes);
    } catch (error) {
      throw RemoteArchiveImportException(error.toString());
    }

    final paths = <String>[];
    for (final entry in files) {
      final target = File(
        p.join(outputDir.path, _archivePrefix(archiveName), entry.relativePath),
      );
      await target.parent.create(recursive: true);
      await target.writeAsBytes(entry.bytes, flush: true);
      paths.add(target.path);
    }

    return paths;
  }

  static String _archivePrefix(String archiveName) {
    final base = p.basenameWithoutExtension(archiveName).trim();
    return base.isEmpty ? 'remote_archive' : base;
  }
}
