import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_local_file_port.freezed.dart';

/// A local backup file exposed to the backup configuration UI.
@freezed
class LocalBackupEntry with _$LocalBackupEntry {
  const factory LocalBackupEntry({required String name, required String path}) =
      _LocalBackupEntry;
}

/// Local backup listing and byte access used by [BackupConfigPage].
abstract interface class BackupLocalFilePort {
  bool get isAvailable;

  Future<List<LocalBackupEntry>> listBackups();

  Future<List<int>> readBytes(LocalBackupEntry entry);
}
