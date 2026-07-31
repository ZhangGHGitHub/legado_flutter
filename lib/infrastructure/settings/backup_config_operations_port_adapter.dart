import 'dart:io';

import '../../application/settings/backup_config_operations_port.dart';
import '../../domain/remote/webdav_entry.dart';
import '../../services/backup_service.dart';

final class BackupConfigOperationsPortAdapter
    implements BackupConfigOperationsPort {
  const BackupConfigOperationsPortAdapter(this._service);

  final BackupService _service;

  @override
  Future<File> backupToLocalFile() => _service.backupToLocalFile();

  @override
  Future<void> pickAndRestore() async {
    await _service.pickAndRestore();
  }

  @override
  Future<void> restoreFromBytes(List<int> bytes) =>
      _service.restoreFromBytes(bytes);

  @override
  Future<void> backupToWebDav() => _service.backupToWebDav();

  @override
  Future<List<WebDavEntry>> listWebDavBackups() => _service.listWebDavBackups();

  @override
  Future<void> restoreFromWebDav(String remotePath) =>
      _service.restoreFromWebDav(remotePath);

  @override
  Future<void> deleteWebDavBackup(String remotePath) =>
      _service.deleteWebDavBackup(remotePath);

  @override
  Future<void> renameWebDavBackup(String remotePath, String newName) =>
      _service.renameWebDavBackup(remotePath, newName);
}
