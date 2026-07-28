import '../remote/legacy_room_import_report.dart';

/// 原版 Kotlin Room 数据库导入用例。
abstract interface class LegacyRoomImportUseCase {
  LegacyRoomImportReport importDatabase({
    required String sourcePath,
    required String backupPath,
    bool replace = false,
  });
}
