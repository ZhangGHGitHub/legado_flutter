/// 远端书籍压缩包中的可导入文件。
class RemoteArchiveBookFile {
  const RemoteArchiveBookFile({
    required this.relativePath,
    required this.bytes,
  });

  final String relativePath;
  final List<int> bytes;
}

/// 远端书籍 ZIP 解析所需的最小引擎端口。
abstract interface class RemoteArchiveParserPort {
  bool get isAvailable;

  List<RemoteArchiveBookFile> parseZipBookFiles(List<int> bytes);
}
