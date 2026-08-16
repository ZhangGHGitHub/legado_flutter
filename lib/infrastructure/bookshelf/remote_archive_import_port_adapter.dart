import 'dart:io';

import '../../application/bookshelf/remote_archive_import_port.dart';
import '../../services/remote_archive_import_service.dart';

/// 将既有远程 ZIP 导入 service 接入远程书籍应用端口。
final class RemoteArchiveImportPortAdapter implements RemoteArchiveImportPort {
  const RemoteArchiveImportPortAdapter(this._service);

  final RemoteArchiveImportService _service;

  @override
  Future<List<String>> extractZipBookFiles(
    List<int> bytes, {
    required Directory outputDir,
    required String archiveName,
  }) => _service.extractZipBookFiles(
    bytes,
    outputDir: outputDir,
    archiveName: archiveName,
  );
}
