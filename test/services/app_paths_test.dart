import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/file_system/app_paths_port_adapter.dart';
import 'package:legado_flutter/services/app_paths.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('legado_paths_test_');
    SharedPreferences.setMockInitialValues({});
    await AppDataPrefs.saveDataDir(tempRoot.path);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('AppPaths uses custom data root', () async {
    final root = await AppPaths.dataRoot();
    expect(root.path, tempRoot.path);

    final dbPath = await AppPaths.dbPath();
    expect(dbPath, p.join(tempRoot.path, AppPaths.dbFileName));

    final cacheDir = await AppPaths.bookCacheDir();
    expect(cacheDir.path, p.join(tempRoot.path, AppPaths.bookCacheFolder));
    expect(await cacheDir.exists(), isTrue);

    final backupsDir = await AppPaths.backupsDir();
    expect(backupsDir.path, p.join(tempRoot.path, AppPaths.backupsFolder));
    expect(await backupsDir.exists(), isTrue);
  });

  test('AppPathsPortAdapter exposes the configured data root', () async {
    final root = await const AppPathsPortAdapter().dataRoot();
    expect(root.path, tempRoot.path);
  });

  test('AppDataPrefs clears override when empty', () async {
    await AppDataPrefs.saveDataDir('');
    expect(await AppDataPrefs.loadDataDir(), isNull);
  });
}
