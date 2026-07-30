import 'dart:io';

/// 文件管理等应用用例所需的数据根目录端口。
abstract interface class AppPathsPort {
  Future<Directory> dataRoot();
}
