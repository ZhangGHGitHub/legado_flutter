import '../../domain/ports/legacy_room_import_use_case.dart';
import '../../domain/ports/legacy_room_import_port.dart';
import '../../domain/remote/legacy_room_import_report.dart';

/// Application use case for importing the original Room database.
class LegacyRoomImportService implements LegacyRoomImportUseCase {
  const LegacyRoomImportService(this._port);

  final LegacyRoomImportPort _port;

  @override
  LegacyRoomImportReport importDatabase({
    required String sourcePath,
    required String backupPath,
    bool replace = false,
  }) {
    if (sourcePath.trim().isEmpty) {
      throw ArgumentError.value(sourcePath, 'sourcePath');
    }
    if (backupPath.trim().isEmpty) {
      throw ArgumentError.value(backupPath, 'backupPath');
    }
    return LegacyRoomImportReport.fromJson(
      _port.importDatabase(
        sourcePath: sourcePath,
        backupPath: backupPath,
        replace: replace,
      ),
    );
  }
}
