import 'dart:io';

import '../../application/file_system/app_paths_port.dart';
import '../../services/app_paths.dart';

final class AppPathsPortAdapter implements AppPathsPort {
  const AppPathsPortAdapter();

  @override
  Future<Directory> dataRoot() => AppPaths.dataRoot();

  @override
  Future<Directory> backupsDir() => AppPaths.backupsDir();
}
