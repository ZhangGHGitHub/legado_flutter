/// Database backup operations exposed to the application layer.
abstract interface class BackupPort {
  bool get isAvailable;

  String get engineVersion;

  String exportBackup();

  void restoreBackup({required String json, required bool replace});
}
