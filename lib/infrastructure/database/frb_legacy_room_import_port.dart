import '../../bridge/legado_db_bridge.dart';
import '../../domain/ports/legacy_room_import_port.dart';
import '../../src/rust/api/db.dart' as rust_db;

/// FRB adapter for the transactional Kotlin Room import.
class FrbLegacyRoomImportPort implements LegacyRoomImportPort {
  @override
  String importDatabase({
    required String sourcePath,
    required String? backupPath,
    required bool replace,
  }) {
    LegadoDbBridge.requireReady();
    return rust_db.dbImportLegacyRoomDatabase(
      path: sourcePath,
      backupPath: backupPath,
      replace: replace,
    );
  }
}
