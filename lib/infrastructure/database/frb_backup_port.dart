import '../../bridge/legado_db_bridge.dart';
import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/backup_port.dart';
import '../../src/rust/api/backup.dart' as backup_api;

/// FRB adapter for Rust database backup operations.
class FrbBackupPort implements BackupPort {
  @override
  bool get isAvailable =>
      LegadoEngineBridge.isAvailable && LegadoDbBridge.isReady;

  @override
  String get engineVersion => LegadoEngineBridge.engineVersion();

  @override
  String exportBackup() => backup_api.exportBackup();

  @override
  void restoreBackup({required String json, required bool replace}) {
    backup_api.restoreBackup(json: json, replace: replace);
  }
}
