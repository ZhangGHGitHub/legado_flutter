import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Web API Rust 集成', () {
    late bool rustReady;

    setUpAll(() async {
      await LegadoEngineBridge.tryInit();
      rustReady = LegadoEngineBridge.isAvailable;
      if (rustReady) {
        final tempDir = await Directory.systemTemp.createTemp('legado_webapi_');
        await LegadoDbBridge.init(
          dbPathOverride: p.join(tempDir.path, 'legado.db'),
        );
      }
    });

    test('start status stop lifecycle', () async {
      if (!rustReady) return;

      final status = await LegadoEngineBridge.startWebApi(
        port: 19877,
        token: 'itest',
      );
      expect(status.running, isTrue);
      expect(status.port, 19877);

      final current = LegadoEngineBridge.webApiStatus();
      expect(current?.running, isTrue);

      await LegadoEngineBridge.stopWebApi();
      expect(LegadoEngineBridge.webApiStatus()?.running ?? true, isFalse);
    });
  });
}
