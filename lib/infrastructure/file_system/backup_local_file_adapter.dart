import 'dart:io';

import '../../bridge/legado_db_bridge.dart';
import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/backup_local_file_port.dart';
import '../../services/backup_service.dart';

/// File-system adapter for local backups listed by [BackupService].
class FileSystemBackupLocalFileAdapter implements BackupLocalFilePort {
  FileSystemBackupLocalFileAdapter(this._service);

  final BackupService _service;

  @override
  bool get isAvailable =>
      LegadoEngineBridge.isAvailable && LegadoDbBridge.isReady;

  @override
  Future<List<LocalBackupEntry>> listBackups() async {
    final files = await _service.listLocalBackups();
    return files
        .map(
          (file) => LocalBackupEntry(
            name: file.uri.pathSegments.last,
            path: file.path,
          ),
        )
        .toList();
  }

  @override
  Future<List<int>> readBytes(LocalBackupEntry entry) {
    return File(entry.path).readAsBytes();
  }
}
