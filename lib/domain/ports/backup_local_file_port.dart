/// A local backup file exposed to the backup configuration UI.
class LocalBackupEntry {
  const LocalBackupEntry({required this.name, required this.path});

  final String name;
  final String path;
}

/// Local backup listing and byte access used by [BackupConfigPage].
abstract interface class BackupLocalFilePort {
  bool get isAvailable;

  Future<List<LocalBackupEntry>> listBackups();

  Future<List<int>> readBytes(LocalBackupEntry entry);
}
