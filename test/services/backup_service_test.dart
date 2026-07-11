import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/services/backup_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'legado_theme_mode': 'light'});

  test('BackupService creates full backup JSON when engine ready', () async {
    await LegadoEngineBridge.tryInit();
    if (!LegadoEngineBridge.isAvailable) return;

    final tempDir = await Directory.systemTemp.createTemp('legado_backup_test_');
    await LegadoDbBridge.init(
      dbPathOverride: p.join(tempDir.path, 'legado.db'),
    );

    final service = BackupService();
    final raw = await service.createFullBackupJson();
    final map = jsonDecode(raw) as Map<String, dynamic>;
    expect(map['version'], 1);
    expect(map['database'], isA<Map>());
    expect(map['settings'], isA<Map>());
    expect((map['database'] as Map)['books'], isA<List>());
  });
}
