import 'dart:io';

/// 远程 ZIP 书籍导入所需的应用端口。
abstract interface class RemoteArchiveImportPort {
  Future<List<String>> extractZipBookFiles(
    List<int> bytes, {
    required Directory outputDir,
    required String archiveName,
  });
}
