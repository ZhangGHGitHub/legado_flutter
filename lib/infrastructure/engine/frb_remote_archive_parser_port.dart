import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/remote_archive_parser_port.dart';
import '../../src/rust/api.dart' as rust_api;
import 'app_error_message.dart';

typedef RustParseRemoteArchiveBookFiles =
    List<rust_api.RemoteArchiveBookFile> Function({required List<int> data});

/// Rust/FRB 远端书籍 ZIP 解析适配器。
class FrbRemoteArchiveParserPort implements RemoteArchiveParserPort {
  const FrbRemoteArchiveParserPort({
    bool Function()? isAvailable,
    RustParseRemoteArchiveBookFiles? parseRemoteArchiveBookFiles,
  }) : _isAvailable = isAvailable ?? _defaultIsAvailable,
       _parseRemoteArchiveBookFiles =
           parseRemoteArchiveBookFiles ?? rust_api.parseRemoteArchiveBookFiles;

  final bool Function() _isAvailable;
  final RustParseRemoteArchiveBookFiles _parseRemoteArchiveBookFiles;

  @override
  bool get isAvailable => _isAvailable();

  @override
  List<RemoteArchiveBookFile> parseZipBookFiles(List<int> bytes) {
    if (!isAvailable) throw StateError('Rust engine not available');
    try {
      return _parseRemoteArchiveBookFiles(data: bytes)
          .map(
            (file) => RemoteArchiveBookFile(
              relativePath: file.relativePath,
              bytes: file.bytes,
            ),
          )
          .toList(growable: false);
    } catch (error) {
      final message = appErrorMessage(error);
      if (message != null) throw RemoteArchiveParserException(message);
      rethrow;
    }
  }

  static bool _defaultIsAvailable() => LegadoEngineBridge.isAvailable;
}
