/// 原版 Kotlin Room 数据库导入能力端口。
abstract interface class LegacyRoomImportPort {
  String importDatabase({
    required String sourcePath,
    required String backupPath,
    required bool replace,
  });
}
