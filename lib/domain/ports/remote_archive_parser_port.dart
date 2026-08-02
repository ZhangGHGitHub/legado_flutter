import 'package:freezed_annotation/freezed_annotation.dart';

part 'remote_archive_parser_port.freezed.dart';

/// 远端书籍压缩包中的可导入文件。
@Freezed(makeCollectionsUnmodifiable: false)
class RemoteArchiveBookFile with _$RemoteArchiveBookFile {
  const factory RemoteArchiveBookFile({
    required String relativePath,
    required List<int> bytes,
  }) = _RemoteArchiveBookFile;
}

class RemoteArchiveParserException implements Exception {
  const RemoteArchiveParserException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 远端书籍 ZIP 解析所需的最小引擎端口。
abstract interface class RemoteArchiveParserPort {
  bool get isAvailable;

  List<RemoteArchiveBookFile> parseZipBookFiles(List<int> bytes);
}
